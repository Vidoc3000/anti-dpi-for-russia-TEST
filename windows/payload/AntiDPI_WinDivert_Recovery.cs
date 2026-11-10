// Automatic local WinDivert recovery. Igor Krauch (github.com/igareck).
// No website probes, periodic driver deletion, or termination of foreign processes.
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace AntiDPI.Public10
{
    // An uninstall request must remain visible even after its files are removed.
    // The kernel event outlives directory deletion and prevents the watchdog from
    // resurrecting a deliberately stopped installation.
    public sealed class WinDivertLifecycle : IDisposable
    {
        EventWaitHandle stop;
        static string Name(string bundle)
        {
            string root = Path.GetDirectoryName(Path.GetFullPath(bundle).TrimEnd(Path.DirectorySeparatorChar)).ToUpperInvariant();
            using (System.Security.Cryptography.SHA256 sha = System.Security.Cryptography.SHA256.Create())
                return @"Global\AntiDPI_Stop_" + BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(root))).Replace("-", "");
        }
        public WinDivertLifecycle(string bundle)
        {
            if (Environment.OSVersion.Platform != PlatformID.Win32NT) return;
            bool created;
            stop = new EventWaitHandle(false, EventResetMode.ManualReset, Name(bundle), out created);
            if (!created) {
                bool stopping = stop.WaitOne(0); stop.Dispose(); stop = null;
                throw new IOException(stopping ? "Эта установка завершает работу или удаляется. Дождитесь завершения." :
                    "Эта установка уже открыта в другом окне. Используйте работающее окно программы.");
            }
        }
        public bool StopRequested { get { return stop != null && stop.WaitOne(0); } }
        public static bool RequestStop(string bundle)
        {
            if (Environment.OSVersion.Platform != PlatformID.Win32NT) return false;
            try { using (EventWaitHandle handle = EventWaitHandle.OpenExisting(Name(bundle))) handle.Set(); return true; }
            catch (WaitHandleCannotBeOpenedException) { return false; /* No running controller. */ }
        }
        public void Dispose() { if (stop != null) { stop.Dispose(); stop = null; } }
    }

    public sealed class WinDivertEngineException : IOException
    {
        public string DriverError { get; private set; }
        public WinDivertEngineException(string detail, string log)
            : base("WinDivert: " + detail + ". Лог: " + log) { DriverError = detail; }
    }

    public sealed class WinDivertState
    {
        public bool Exists, Owned, FilesReady;
        public int Error, State, StartType, CheckPoint, WaitHint;
        public string ImagePath = "", ExpectedPath = "", FileProblem = "", DllVersion = "", DriverVersion = "";
        public override string ToString()
        {
            return "exists=" + Exists + "; state=" + State + "; start=" + StartType +
                "; error=" + Error + "; owned=" + Owned + "; checkpoint=" + CheckPoint +
                "; wait_hint=" + WaitHint + "; path=" + ImagePath + "; expected=" + ExpectedPath +
                "; files_ready=" + FilesReady + "; dll_version=" + DllVersion + "; driver_version=" + DriverVersion + "; file_problem=" + FileProblem;
        }
    }

    public sealed class WinDivertUsers
    {
        public bool Known;
        public int Error;
        public int[] ProcessIds = new int[0];
    }

    public enum WinDivertRepairAction { Retry, Reconfigure, Reset, Refuse }

    // A replaceable backend makes all decision branches testable without a live driver.
    public interface IWinDivertBackend
    {
        WinDivertState Read();
        WinDivertUsers Users();
        void Reconfigure(WinDivertState before);
        void Reset(WinDivertState before);
    }

    public sealed class WinDivertRepairResult
    {
        public bool Retry, Changed;
        public string Reason = "";
        public WinDivertRepairAction Action;
    }

    public sealed class WinDivertRecoveryBudget
    {
        readonly Queue<DateTime> attempts = new Queue<DateTime>();
        public bool TryBegin(DateTime now, out int number, out int delayMilliseconds)
        {
            lock (attempts) {
                while (attempts.Count != 0 && now - attempts.Peek() >= TimeSpan.FromMinutes(10)) attempts.Dequeue();
                number = attempts.Count + 1;
                delayMilliseconds = number == 1 ? 1000 : number == 2 ? 3000 : 7000;
                if (attempts.Count >= 3) return false;
                attempts.Enqueue(now);
                return true;
            }
        }
    }

    public static class WinDivertRecovery
    {
        static readonly object logSync = new object();
        public static int NativeError(string reason)
        {
            string text = (reason ?? "").ToLowerInvariant();
            Match number = Regex.Match(text, @"(?:win32|error|ошибка)[\s=:()]+(\d{1,5})(?!\d)");
            int code;
            if (number.Success && Int32.TryParse(number.Groups[1].Value, out code)) return code;
            int[] known = { 1058, 1060, 1072, 654, 577, 1275, 5, 87, 2, 3, 6 };
            foreach (int value in known) {
                string message = new Win32Exception(value).Message;
                if (message.Length > 8 && text.IndexOf(message.ToLowerInvariant(), StringComparison.Ordinal) >= 0) return value;
            }
            if (text.Contains("service cannot be started") || text.Contains("служба отключена")) return 1058;
            if (text.Contains("digital signature") || text.Contains("цифровую подпись")) return 577;
            if (text.Contains("access is denied") || text.Contains("отказано в доступе")) return 5;
            if (text.Contains("parameter is incorrect") || text.Contains("неверно задан параметр")) return 87;
            if (text.Contains("marked for deletion")) return 1072;
            return 0;
        }

        public static WinDivertRepairAction Decide(WinDivertState state, WinDivertUsers users, string reason, int attempt)
        {
            if (!state.FilesReady) return WinDivertRepairAction.Refuse;
            if (state.Error == 1072) return WinDivertRepairAction.Retry; // Close/query and allow pending deletion to finish.
            if (state.Error != 0) return WinDivertRepairAction.Refuse;
            if (!state.Exists) return WinDivertRepairAction.Retry; // Normal on-demand registration.
            bool configuration = state.StartType == 4 ||
                !String.Equals(state.ImagePath, state.ExpectedPath, StringComparison.OrdinalIgnoreCase);
            int code = NativeError(reason);
            if (code == 5 || code == 87 || code == 577 || code == 1275) return WinDivertRepairAction.Refuse;
            bool resettable = code == 1058 || code == 1060 || code == 1072 || code == 654 || code == 2 || code == 3 || code == 6 ||
                reason == "SERVICE_STOPPED" || reason == "SERVICE_MISSING" || reason == "SERVICE_PENDING_TIMEOUT";
            // A query alone is the first step for an otherwise correctly configured service.
            if (!configuration && (attempt == 1 || !resettable)) return WinDivertRepairAction.Retry;
            if (!state.Owned || !users.Known || users.ProcessIds.Length != 0) return WinDivertRepairAction.Refuse;
            return configuration ? WinDivertRepairAction.Reconfigure : WinDivertRepairAction.Reset;
        }

        public static void Log(string path, string message)
        {
            lock (logSync) {
                Directory.CreateDirectory(Path.GetDirectoryName(path));
                File.AppendAllText(path, DateTime.UtcNow.ToString("o") + " " + message.Replace("\r", " ").Replace("\n", " ") +
                    Environment.NewLine, new UTF8Encoding(false));
            }
        }

        public static WinDivertRepairResult RepairWithBackend(IWinDivertBackend backend, string log, string reason, int attempt)
        {
            WinDivertRepairResult result = new WinDivertRepairResult();
            WinDivertState before = backend.Read();
            Log(log, "BEFORE attempt=" + attempt + "; reason=" + reason + "; " + before);
            WinDivertUsers users = new WinDivertUsers();
            bool configuration = before.Exists && (before.StartType == 4 ||
                !String.Equals(before.ImagePath, before.ExpectedPath, StringComparison.OrdinalIgnoreCase));
            if (before.FilesReady && before.Error == 0 && before.Exists && before.Owned && (configuration || attempt > 1)) {
                users = backend.Users();
                Log(log, "USERS known=" + users.Known + "; error=" + users.Error + "; pids=" + String.Join(",", users.ProcessIds));
            }
            result.Action = Decide(before, users, reason, attempt);
            Log(log, "ACTION " + result.Action);
            if (result.Action == WinDivertRepairAction.Refuse) {
                int nativeCode = NativeError(reason);
                result.Reason = !before.FilesReady ? before.FileProblem : before.Error != 0 ?
                    "Не удалось прочитать состояние службы: Win32 " + before.Error :
                    nativeCode == 5 || nativeCode == 87 || nativeCode == 577 || nativeCode == 1275 ?
                    "Win32 " + nativeCode + ": проверьте доступ, параметры фильтра или блокировку защитным ПО; запись службы сохранена." : !before.Owned ?
                    "Принадлежность службы этой установке не подтверждена; запись сохранена." : !users.Known ?
                    "Не удалось надёжно проверить использование драйвера; служба сохранена." : users.ProcessIds.Length != 0 ?
                    "WinDivert используется другими процессами: " + String.Join(", ", users.ProcessIds) :
                    "Ошибка требует исправления параметров, доступа или блокировки защитным ПО; служба сохранена.";
                Log(log, "BLOCKED " + result.Reason);
                return result;
            }
            if (result.Action == WinDivertRepairAction.Reconfigure) { backend.Reconfigure(before); result.Changed = true; }
            if (result.Action == WinDivertRepairAction.Reset) { backend.Reset(before); result.Changed = true; }
            result.Retry = true;
            result.Reason = result.Changed ? "Состояние службы исправлено; требуется повторный запуск движка." :
                "Состояние службы запрошено; повторный запуск без удаления записи.";
            Log(log, "AFTER " + backend.Read() + "; " + result.Reason);
            return result;
        }

        public static WinDivertRepairResult Repair(string bundle, string log, string reason, int attempt)
        {
            Mutex mutex = null; bool held = false;
            try {
                mutex = new Mutex(false, @"Global\AntiDPI_WinDivert_Recovery");
                try { held = mutex.WaitOne(3000); } catch (AbandonedMutexException) { held = true; }
                if (!held) return new WinDivertRepairResult { Reason = "Восстановление уже выполняется другим экземпляром программы." };
                return RepairWithBackend(new NativeWinDivertBackend(bundle), log, reason, attempt);
            }
            catch (Exception error) {
                try { Log(log, "RECOVERY_ERROR " + error.GetBaseException().Message); } catch (Exception) { }
                return new WinDivertRepairResult { Reason = error.GetBaseException().Message };
            }
            finally { if (held) mutex.ReleaseMutex(); if (mutex != null) mutex.Dispose(); }
        }
    }

    public sealed class WinDivertHealthMonitor
    {
        readonly IWinDivertBackend backend;
        DateTime next = DateTime.MinValue, transition = DateTime.MinValue;
        int previousState, previousCheckpoint;
        public WinDivertState LastState { get; private set; }
        public WinDivertHealthMonitor(string bundle) : this(new NativeWinDivertBackend(bundle)) { }
        public WinDivertHealthMonitor(IWinDivertBackend value) { backend = value; }
        public string Poll(DateTime now)
        {
            if (now < next) return "";
            next = now.AddSeconds(5);
            WinDivertState state = backend.Read(); LastState = state;
            if (state.Error != 0 && state.Error != 1072) return ""; // An unreadable status is not proof of a broken driver.
            if (state.Error == 1072) {
                if (transition == DateTime.MinValue) transition = now;
                return (now - transition).TotalSeconds >= 10 ? "Win32 1072" : "";
            }
            if (state.Exists && state.State == 4) { transition = DateTime.MinValue; return ""; }
            if (transition == DateTime.MinValue || state.State != previousState || state.CheckPoint != previousCheckpoint) transition = now;
            previousState = state.State; previousCheckpoint = state.CheckPoint;
            int grace = state.State == 2 || state.State == 3 ? Math.Min(60, Math.Max(15, state.WaitHint / 1000 + 5)) : 10;
            if ((now - transition).TotalSeconds < grace) return "";
            return !state.Exists ? "SERVICE_MISSING" : state.State == 1 ? "SERVICE_STOPPED" : "SERVICE_PENDING_TIMEOUT";
        }
    }

    public sealed class NativeWinDivertBackend : IWinDivertBackend
    {
        const string ServiceName = "WinDivert";
        readonly string bundle, root, driver, dll;
        readonly bool installation;
        static readonly IntPtr Invalid = new IntPtr(-1);
        public NativeWinDivertBackend(string directory)
        {
            bundle = Path.GetFullPath(directory).TrimEnd(Path.DirectorySeparatorChar);
            root = Path.GetDirectoryName(bundle);
            driver = Path.Combine(bundle, "WinDivert64.sys"); dll = Path.Combine(bundle, "WinDivert.dll");
            string marker = Path.Combine(root, ".antidpi-install.json");
            if (File.Exists(marker)) {
                string json = File.ReadAllText(marker);
                Match schema = Regex.Match(json, "\"Schema\"\\s*:\\s*\"antidpi[.]zapret[.]install[.]v1\"");
                Match path = Regex.Match(json, "\"InstallRoot\"\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"");
                installation = schema.Success && path.Success && String.Equals(Path.GetFullPath(Regex.Unescape(path.Groups[1].Value)).TrimEnd('\\'), root.TrimEnd('\\'), StringComparison.OrdinalIgnoreCase);
            }
        }

        [StructLayout(LayoutKind.Sequential)] struct Status { public uint Type, State, Accepted, Win32Exit, SpecificExit, CheckPoint, WaitHint, Pid, Flags; }
        [StructLayout(LayoutKind.Sequential)] struct Config { public uint Type, StartType, Error; public IntPtr Path, Group; public uint Tag; public IntPtr Dependencies, Account, Display; }
        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern IntPtr OpenSCManager(string machine, string database, uint access);
        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern IntPtr OpenService(IntPtr manager, string name, uint access);
        [DllImport("advapi32.dll", SetLastError = true)] static extern bool CloseServiceHandle(IntPtr handle);
        [DllImport("advapi32.dll", SetLastError = true)] static extern bool QueryServiceStatusEx(IntPtr service, int level, out Status status, int size, out int needed);
        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool QueryServiceConfig(IntPtr service, IntPtr config, int size, out int needed);
        [DllImport("advapi32.dll", SetLastError = true)] static extern bool ControlService(IntPtr service, uint control, out Status status);
        [DllImport("advapi32.dll", SetLastError = true)] static extern bool DeleteService(IntPtr service);
        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern bool ChangeServiceConfig(IntPtr service, uint type, uint start, uint error, string path, string group, IntPtr tag, string dependencies, string account, string password, string display);

        static string Normalize(string path)
        {
            path = Environment.ExpandEnvironmentVariables(path ?? "").Trim().Trim('"');
            if (path.StartsWith(@"\??\", StringComparison.Ordinal)) path = path.Substring(4);
            if (path.StartsWith(@"\SystemRoot\", StringComparison.OrdinalIgnoreCase)) path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), path.Substring(12));
            return Path.GetFullPath(path);
        }
        bool IsOwnedPath(string path)
        {
            if (!installation || !path.StartsWith(root.TrimEnd('\\') + "\\", StringComparison.OrdinalIgnoreCase)) return false;
            // A textual prefix through a junction is not proof of ownership.
            string current = path;
            while (!String.IsNullOrEmpty(current)) {
                if ((File.Exists(current) || Directory.Exists(current)) && (File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0) return false;
                string parent = Path.GetDirectoryName(current);
                if (parent == current) break;
                current = parent;
            }
            return true;
        }
        public WinDivertState Read()
        {
            WinDivertState state = new WinDivertState { ExpectedPath = driver, FilesReady = true };
            foreach (string name in new string[] { "winws2.exe", "WinDivert.dll", "WinDivert64.sys" }) {
                if (!File.Exists(Path.Combine(bundle, name))) { state.FilesReady = false; state.FileProblem = "Отсутствует " + Path.Combine(bundle, name) + ". Проверьте карантин антивируса или переустановите программу."; }
            }
            if (state.FilesReady) {
                try {
                    FileVersionInfo dllInfo = FileVersionInfo.GetVersionInfo(dll), driverInfo = FileVersionInfo.GetVersionInfo(driver);
                    state.DllVersion = dllInfo.FileVersion ?? ""; state.DriverVersion = driverInfo.FileVersion ?? "";
                    if (dllInfo.FileMajorPart != 0 && driverInfo.FileMajorPart != 0 &&
                        (dllInfo.FileMajorPart != driverInfo.FileMajorPart || dllInfo.FileMinorPart != driverInfo.FileMinorPart)) {
                        state.FilesReady = false;
                        state.FileProblem = "Версии WinDivert.dll и WinDivert64.sys несовместимы. Переустановите цельную официальную сборку; запись службы сохранена.";
                    }
                }
                catch (Exception error) { state.FilesReady = false; state.FileProblem = "Не удалось проверить файлы WinDivert: " + error.GetBaseException().Message; }
            }
            if (Environment.OSVersion.Platform != PlatformID.Win32NT) { state.Error = 50; return state; }
            IntPtr manager = OpenSCManager(null, null, 1);
            if (manager == IntPtr.Zero) { state.Error = Marshal.GetLastWin32Error(); return state; }
            IntPtr service = IntPtr.Zero, memory = IntPtr.Zero;
            try {
                service = OpenService(manager, ServiceName, 5);
                if (service == IntPtr.Zero) { int error = Marshal.GetLastWin32Error(); state.Error = error == 1060 ? 0 : error; return state; }
                state.Exists = true;
                Status status; int needed;
                if (!QueryServiceStatusEx(service, 0, out status, Marshal.SizeOf(typeof(Status)), out needed)) throw new Win32Exception();
                state.State = (int)status.State; state.CheckPoint = (int)status.CheckPoint; state.WaitHint = (int)status.WaitHint;
                QueryServiceConfig(service, IntPtr.Zero, 0, out needed);
                if (needed <= 0 || needed > 65536) throw new IOException("Некорректный размер конфигурации службы WinDivert.");
                memory = Marshal.AllocHGlobal(needed);
                if (!QueryServiceConfig(service, memory, needed, out needed)) throw new Win32Exception();
                Config config = (Config)Marshal.PtrToStructure(memory, typeof(Config));
                state.StartType = (int)config.StartType;
                state.ImagePath = Normalize(Marshal.PtrToStringUni(config.Path));
                state.Owned = IsOwnedPath(state.ImagePath);
                return state;
            }
            catch (Win32Exception error) { state.Error = error.NativeErrorCode; return state; }
            catch (Exception error) { state.Error = 13; state.FileProblem = error.GetBaseException().Message; return state; }
            finally { if (memory != IntPtr.Zero) Marshal.FreeHGlobal(memory); if (service != IntPtr.Zero) CloseServiceHandle(service); CloseServiceHandle(manager); }
        }

        public WinDivertUsers Users() { return ReflectUsers.Read(dll); }
        void ValidateMutation(WinDivertState before)
        {
            WinDivertState current = Read();
            if (!current.Owned || !current.FilesReady || current.Error != 0 || !current.Exists ||
                !String.Equals(current.ImagePath, before.ImagePath, StringComparison.OrdinalIgnoreCase)) throw new IOException("Состояние или принадлежность службы изменились; вмешательство отменено.");
            WinDivertUsers users = Users();
            if (!users.Known || users.ProcessIds.Length != 0) throw new IOException("Драйвер используется или проверка использования не завершена; служба сохранена.");
        }
        void Mutate(WinDivertState before, bool remove)
        {
            ValidateMutation(before);
            IntPtr manager = OpenSCManager(null, null, 1), service = IntPtr.Zero;
            if (manager == IntPtr.Zero) throw new Win32Exception();
            try {
                service = OpenService(manager, ServiceName, 4 | 32 | (remove ? 65536U : 2U));
                if (service == IntPtr.Zero) throw new Win32Exception();
                Status status; int needed;
                if (!QueryServiceStatusEx(service, 0, out status, Marshal.SizeOf(typeof(Status)), out needed)) throw new Win32Exception();
                if (status.State != 1) {
                    if (status.State != 3 && !ControlService(service, 1, out status)) {
                        int error = Marshal.GetLastWin32Error(); if (error != 1062) throw new Win32Exception(error);
                    }
                    Stopwatch wait = Stopwatch.StartNew();
                    do {
                        if (!QueryServiceStatusEx(service, 0, out status, Marshal.SizeOf(typeof(Status)), out needed)) throw new Win32Exception();
                        if (status.State == 1) break;
                        if (wait.ElapsedMilliseconds >= 10000) throw new TimeoutException("Служба WinDivert не остановилась; принудительное удаление не выполнено. Может потребоваться перезагрузка Windows.");
                        Thread.Sleep(100);
                    } while (true);
                }
                // The reflection observer closes its own handle before this point.
                ValidateMutation(before);
                if (remove) { if (!DeleteService(service)) throw new Win32Exception(); }
                else if (!ChangeServiceConfig(service, UInt32.MaxValue, 3, UInt32.MaxValue, "\"" + driver + "\"", null, IntPtr.Zero, null, null, null, null)) throw new Win32Exception();
            }
            finally { if (service != IntPtr.Zero) CloseServiceHandle(service); CloseServiceHandle(manager); }
            if (remove) {
                Stopwatch wait = Stopwatch.StartNew();
                while (true) {
                    WinDivertState current = Read();
                    if (!current.Exists && current.Error == 0) break;
                    if (wait.ElapsedMilliseconds > 5000) throw new TimeoutException("Удаление службы ещё не завершено. Повторное создание не выполняется до освобождения Windows всех ссылок.");
                    Thread.Sleep(100);
                }
            }
        }
        public void Reconfigure(WinDivertState before) { Mutate(before, false); }
        public void Reset(WinDivertState before) { Mutate(before, true); }
    }

    internal sealed class ReflectUsers : IDisposable
    {
        IntPtr module;
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] static extern IntPtr LoadLibraryEx(string path, IntPtr file, uint flags);
        [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr GetProcAddress(IntPtr module, string name);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] static extern uint GetModuleFileName(IntPtr module, StringBuilder name, int length);
        [DllImport("kernel32.dll")] static extern bool FreeLibrary(IntPtr module);
        [UnmanagedFunctionPointer(CallingConvention.Winapi, CharSet = CharSet.Ansi, SetLastError = true)] delegate IntPtr Open(string filter, int layer, short priority, ulong flags);
        [UnmanagedFunctionPointer(CallingConvention.Winapi, SetLastError = true)] delegate bool Shutdown(IntPtr handle, int how);
        [UnmanagedFunctionPointer(CallingConvention.Winapi, SetLastError = true)] delegate bool Receive(IntPtr handle, [Out] byte[] data, uint length, out uint received, [Out] byte[] address);
        [UnmanagedFunctionPointer(CallingConvention.Winapi, SetLastError = true)] delegate bool Close(IntPtr handle);
        Open open; Shutdown shutdown; Receive receive; Close close;
        Delegate Export(string name, Type type)
        {
            IntPtr address = GetProcAddress(module, name);
            if (address == IntPtr.Zero) throw new EntryPointNotFoundException(name);
            return Marshal.GetDelegateForFunctionPointer(address, type);
        }
        ReflectUsers(string dll)
        {
            module = LoadLibraryEx(dll, IntPtr.Zero, 8);
            if (module == IntPtr.Zero) throw new Win32Exception();
            try {
                StringBuilder actual = new StringBuilder(32768);
                if (GetModuleFileName(module, actual, actual.Capacity) == 0 || !String.Equals(Path.GetFullPath(actual.ToString()), Path.GetFullPath(dll), StringComparison.OrdinalIgnoreCase))
                    throw new IOException("Загружена WinDivert.dll из другой папки; вмешательство отменено.");
                open = (Open)Export("WinDivertOpen", typeof(Open)); shutdown = (Shutdown)Export("WinDivertShutdown", typeof(Shutdown));
                receive = (Receive)Export("WinDivertRecv", typeof(Receive)); close = (Close)Export("WinDivertClose", typeof(Close));
            }
            catch { Dispose(); throw; }
        }
        public void Dispose() { if (module != IntPtr.Zero) { FreeLibrary(module); module = IntPtr.Zero; } }
        public static WinDivertUsers Read(string dll)
        {
            ReflectUsers api = null; IntPtr handle = new IntPtr(-1); bool deferred = false;
            try {
                api = new ReflectUsers(dll);
                // Same snapshot protocol as the official windivertctl list sample.
                handle = api.open("true", 4, 0, 1 | 4 | 16);
                if (handle == new IntPtr(-1)) {
                    int error = Marshal.GetLastWin32Error();
                    return new WinDivertUsers { Known = error == 1060, Error = error == 1060 ? 0 : error };
                }
                if (!api.shutdown(handle, 3)) return new WinDivertUsers { Error = Marshal.GetLastWin32Error() };
                IntPtr snapshotHandle = handle; ReflectUsers snapshotApi = api;
                Task<WinDivertUsers> task = Task.Run<WinDivertUsers>(delegate {
                    HashSet<int> pids = new HashSet<int>(); byte[] packet = new byte[65535], address = new byte[80]; uint length;
                    for (int count = 0; count < 65536; count++) {
                        if (!snapshotApi.receive(snapshotHandle, packet, (uint)packet.Length, out length, address)) {
                            int error = Marshal.GetLastWin32Error();
                            return new WinDivertUsers { Known = error == 232, Error = error == 232 ? 0 : error, ProcessIds = new List<int>(pids).ToArray() };
                        }
                        if (address[9] == 8) {
                            int pid = BitConverter.ToInt32(address, 24), layer = BitConverter.ToInt32(address, 28);
                            if (pid != Process.GetCurrentProcess().Id || layer != 4) pids.Add(pid);
                        }
                    }
                    return new WinDivertUsers { Error = 234 };
                });
                if (!task.Wait(2000)) {
                    api.close(handle); handle = new IntPtr(-1);
                    if (!task.Wait(500)) {
                        deferred = true;
                        task.ContinueWith(delegate { snapshotApi.Dispose(); });
                    }
                    return new WinDivertUsers { Error = 1460 };
                }
                return task.GetAwaiter().GetResult();
            }
            catch (Exception) { return new WinDivertUsers { Error = -1 }; }
            finally {
                if (api != null && handle != new IntPtr(-1)) api.close(handle);
                if (api != null && !deferred) api.Dispose();
            }
        }
    }
}
