using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Net.Sockets;
using System.Net.Security;
using System.Security.Authentication;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace AntiDPI.Public10
{
    public sealed class BundleTransferResult
    {
        public bool Success { get; set; }
        public string FailureKind { get; set; }
        public Exception Error { get; set; }
        public string FinalUrl { get; set; }
        public byte[] Content { get; set; }
    }

    // Network I/O runs outside PowerShell so DNS, TLS and a blocked read cannot
    // hide the ten-second progress deadline or prevent Ctrl+C cleanup.
    public sealed class BundleDownloadAttempt : IDisposable
    {
        readonly object sync = new object();
        readonly CancellationTokenSource cancellation = new CancellationTokenSource();
        readonly HttpWebRequest request;
        readonly string destination;
        readonly long estimate;
        readonly bool requireZip;
        readonly long maximumBytes;
        WebResponse response;
        Stream input;
        Stream output;
        long received;
        long length;
        bool disposed;
        public Task<BundleTransferResult> Task { get; private set; }
        public long ReceivedBytes { get { return Interlocked.Read(ref received); } }
        public long TotalBytes { get { long n = Interlocked.Read(ref length); return n > 0 ? n : estimate; } }
        public bool SizeKnown { get { return Interlocked.Read(ref length) > 0; } }

        public BundleDownloadAttempt(string url, string path, long expectedBytes)
            : this(url, path, expectedBytes, true, 0)
        {
        }

        public BundleDownloadAttempt(string url, string path, long expectedBytes, bool zipOnly, long byteLimit)
        {
            destination = path; estimate = Math.Max(1, expectedBytes);
            requireZip = zipOnly; maximumBytes = Math.Max(0, byteLimit);
            request = (HttpWebRequest)WebRequest.Create(url);
            request.UserAgent = "AntiDPI-CLI/1.0";
            request.AllowAutoRedirect = true;
            request.AutomaticDecompression = DecompressionMethods.None;
            request.KeepAlive = false;
            // Async requests are governed by the caller's wall-clock watchdog.
            request.Timeout = Timeout.Infinite;
            request.ReadWriteTimeout = Timeout.Infinite;
            Task = System.Threading.Tasks.Task.Run<BundleTransferResult>(new Func<Task<BundleTransferResult>>(RunAsync));
        }

        async Task<BundleTransferResult> RunAsync()
        {
            BundleTransferResult result = new BundleTransferResult();
            string phase = "Network";
            try {
                WebResponse currentResponse = await request.GetResponseAsync().ConfigureAwait(false);
                lock (sync) {
                    if (disposed) { currentResponse.Dispose(); throw new OperationCanceledException(); }
                    response = currentResponse;
                }
                cancellation.Token.ThrowIfCancellationRequested();
                Interlocked.Exchange(ref length, currentResponse.ContentLength);
                if (maximumBytes > 0 && currentResponse.ContentLength > maximumBytes)
                    throw new InvalidDataException("Источник вернул слишком большой текстовый файл.");
                result.FinalUrl = currentResponse.ResponseUri.AbsoluteUri;
                Stream currentInput = currentResponse.GetResponseStream();
                lock (sync) {
                    if (disposed) { currentInput.Dispose(); throw new OperationCanceledException(); }
                    input = currentInput;
                }
                phase = "File";
                Stream currentOutput;
                lock (sync) {
                    // Aborting a timed-out response must forbid late creation
                    // of its partial file after the caller has cleaned it up.
                    if (disposed) throw new OperationCanceledException();
                    currentOutput = requireZip
                        ? (Stream)new FileStream(destination, FileMode.CreateNew, FileAccess.Write, FileShare.None, 131072, FileOptions.Asynchronous)
                        : new MemoryStream();
                    output = currentOutput;
                }
                byte[] buffer = new byte[131072];
                byte[] signature = new byte[4]; int signatureLength = 0;
                while (true) {
                    cancellation.Token.ThrowIfCancellationRequested();
                    phase = "Network";
                    int count = await currentInput.ReadAsync(buffer, 0, buffer.Length, cancellation.Token).ConfigureAwait(false);
                    if (count == 0) break;
                    for (int i = 0; i < count && signatureLength < 4; i++) signature[signatureLength++] = buffer[i];
                    if (requireZip && signatureLength == 4 && (signature[0] != 80 || signature[1] != 75 || signature[2] != 3 || signature[3] != 4))
                        throw new InvalidDataException("Источник вернул не ZIP-архив (возможно, страницу ошибки).");
                    if (maximumBytes > 0 && ReceivedBytes + count > maximumBytes)
                        throw new InvalidDataException("Источник вернул слишком большой текстовый файл.");
                    phase = "File";
                    await currentOutput.WriteAsync(buffer, 0, count, cancellation.Token).ConfigureAwait(false);
                    Interlocked.Add(ref received, count);
                }
                phase = "Network";
                if (requireZip && (ReceivedBytes < 4 || signatureLength != 4)) throw new InvalidDataException("Получен пустой или неполный ZIP-архив.");
                if (!requireZip && ReceivedBytes == 0) throw new InvalidDataException("Получен пустой текстовый файл.");
                if (currentResponse.ContentLength > 0 && ReceivedBytes != currentResponse.ContentLength)
                    throw new EndOfStreamException("Архив скачан не полностью.");
                phase = "File";
                await currentOutput.FlushAsync(cancellation.Token).ConfigureAwait(false);
                cancellation.Token.ThrowIfCancellationRequested();
                if (!requireZip) result.Content = ((MemoryStream)currentOutput).ToArray();
                result.Success = true;
            }
            catch (Exception error) {
                result.Error = error;
                result.FailureKind = cancellation.IsCancellationRequested ? "Cancelled" : phase;
            }
            finally { CloseStreams(); }
            return result;
        }

        void CloseStreams()
        {
            lock (sync) {
                try { if (input != null) input.Dispose(); } catch (Exception) { }
                try { if (response != null) response.Dispose(); } catch (Exception) { }
                try { if (output != null) output.Dispose(); } catch (Exception) { }
                input = null; response = null; output = null;
            }
        }
        public void Abort()
        {
            try { cancellation.Cancel(); } catch (ObjectDisposedException) { }
            lock (sync) { disposed = true; }
            try { request.Abort(); } catch (Exception) { }
            CloseStreams();
        }
        public void Dispose()
        {
            Abort();
            // Any delayed DNS/TLS operation has an aborted request and closed files.
            // It cannot write to a later attempt, which always has a different path.
            try { Task.Wait(500); } catch (AggregateException) { }
        }
    }

    public static class BundleArchiveInfo
    {
        public static string ReadCommit(string path)
        {
            // git archive stores the commit ID in the ZIP EOCD comment.
            using (FileStream file = File.OpenRead(path)) {
                int size = (int)Math.Min(file.Length, 65557);
                if (size < 22) throw new InvalidDataException("ZIP не содержит конечную запись.");
                byte[] tail = new byte[size]; file.Seek(-size, SeekOrigin.End);
                int offset = 0;
                while (offset < size) { int n = file.Read(tail, offset, size - offset); if (n == 0) throw new EndOfStreamException(); offset += n; }
                for (int i = size - 22; i >= 0; i--) {
                    if (tail[i] != 80 || tail[i + 1] != 75 || tail[i + 2] != 5 || tail[i + 3] != 6) continue;
                    int commentLength = tail[i + 20] | (tail[i + 21] << 8);
                    if (i + 22 + commentLength != size) continue;
                    string commit = Encoding.ASCII.GetString(tail, i + 22, commentLength).Trim().ToLowerInvariant();
                    if (!Regex.IsMatch(commit, "\\A[0-9a-f]{40}\\z", RegexOptions.CultureInvariant))
                        throw new InvalidDataException("В ZIP-архиве ветки master нет полного идентификатора коммита GitHub.");
                    return commit;
                }
                throw new InvalidDataException("Не удалось прочитать коммит из ZIP-архива GitHub.");
            }
        }
    }

    public static class ConsoleEnterPause
    {
        // No line editor: text, Esc and function keys cannot accept this prompt.
        public static bool Wait()
        {
            if (Console.IsInputRedirected) throw new InvalidOperationException("Для продолжения откройте программу в обычном окне консоли.");
            bool previous = Console.TreatControlCAsInput;
            Console.TreatControlCAsInput = true;
            try {
                while (true) {
                    ConsoleKeyInfo key = Console.ReadKey(true);
                    if (key.KeyChar == 3 || (key.Key == ConsoleKey.C && (key.Modifiers & ConsoleModifiers.Control) != 0)) return false;
                    if (key.Key == ConsoleKey.Enter) return true;
                }
            }
            finally { Console.TreatControlCAsInput = previous; }
        }
    }

    public static class ConsoleLineEditor
    {
        [System.Runtime.InteropServices.DllImport("user32.dll")] static extern bool OpenClipboard(IntPtr owner);
        [System.Runtime.InteropServices.DllImport("user32.dll")] static extern bool CloseClipboard();
        [System.Runtime.InteropServices.DllImport("user32.dll")] static extern IntPtr GetClipboardData(uint format);
        [System.Runtime.InteropServices.DllImport("kernel32.dll")] static extern IntPtr GlobalLock(IntPtr value);
        [System.Runtime.InteropServices.DllImport("kernel32.dll")] static extern bool GlobalUnlock(IntPtr value);
        static string Paste()
        {
            if (!OpenClipboard(IntPtr.Zero)) return "";
            try {
                IntPtr handle = GetClipboardData(13);
                if (handle == IntPtr.Zero) return "";
                IntPtr data = GlobalLock(handle);
                if (data == IntPtr.Zero) return "";
                try { return (System.Runtime.InteropServices.Marshal.PtrToStringUni(data) ?? "").Replace("\r", "").Replace("\n", ""); }
                finally { GlobalUnlock(handle); }
            }
            finally { CloseClipboard(); }
        }
        public static string Read(string prompt, string initial)
        {
            StringBuilder text = new StringBuilder(initial);
            int cursor = text.Length, viewport = 0;
            bool previous = Console.TreatControlCAsInput;
            Console.TreatControlCAsInput = true;
            try {
                while (true) {
                    int width = Math.Max(1, Math.Min(Console.WindowWidth, Console.BufferWidth) - prompt.Length - 2);
                    if (cursor < viewport) viewport = cursor;
                    if (cursor - viewport >= width) viewport = cursor - width + 1;
                    string visible = text.ToString().Substring(viewport);
                    if (visible.Length > width) visible = visible.Substring(0, width);
                    Console.Write("\r" + prompt + visible.PadRight(width));
                    Console.SetCursorPosition(prompt.Length + cursor - viewport, Console.CursorTop);
                    ConsoleKeyInfo key = Console.ReadKey(true);
                    if (key.Key == ConsoleKey.Enter) { Console.WriteLine(); return text.ToString(); }
                    if (key.KeyChar == 3 || (key.Key == ConsoleKey.C && (key.Modifiers & ConsoleModifiers.Control) != 0))
                        throw new OperationCanceledException("Ввод отменён.");
                    if (key.Key == ConsoleKey.LeftArrow) cursor = Math.Max(0, cursor - 1);
                    else if (key.Key == ConsoleKey.RightArrow) cursor = Math.Min(text.Length, cursor + 1);
                    else if (key.Key == ConsoleKey.Home) cursor = 0;
                    else if (key.Key == ConsoleKey.End) cursor = text.Length;
                    else if (key.Key == ConsoleKey.Backspace && cursor > 0) { text.Remove(--cursor, 1); }
                    else if (key.Key == ConsoleKey.Delete && cursor < text.Length) text.Remove(cursor, 1);
                    else if (key.Key == ConsoleKey.U && (key.Modifiers & ConsoleModifiers.Control) != 0) { text.Clear(); cursor = 0; }
                    else if ((key.Key == ConsoleKey.V && (key.Modifiers & ConsoleModifiers.Control) != 0) ||
                             (key.Key == ConsoleKey.Insert && (key.Modifiers & ConsoleModifiers.Shift) != 0)) {
                        string value = Paste(); text.Insert(cursor, value); cursor += value.Length;
                    }
                    else if (!Char.IsControl(key.KeyChar)) { text.Insert(cursor++, key.KeyChar); }
                }
            }
            finally { Console.TreatControlCAsInput = previous; }
        }
    }

    // Native callbacks never invoke PowerShell or write to its console.
    public sealed class NativeStartupException : IOException
    {
        public int NativeExitCode { get; private set; }
        public NativeStartupException(string stage, int code, string logPath)
            : base("Windows не удалось инициализировать DLL winws2: " + EngineStartupPolicy.FormatExit(code) +
                   ". Этап: " + stage + ". Выполнено попыток: " + EngineStartupPolicy.MaxAttempts + ". Лог: " + logPath)
        { NativeExitCode = code; }
    }

    public static class EngineStartupPolicy
    {
        public const int MaxAttempts = 3;
        public static bool IsDllInitFailure(int code) { return unchecked((uint)code) == 0xC0000142U; }
        public static string FormatExit(int code) { return code + " (0x" + unchecked((uint)code).ToString("X8") + ")"; }
        public static int RetryDelayMilliseconds(int attempt) { return 1000 * attempt; }
    }

    public sealed class EngineSession : IDisposable
    {
        readonly object sync = new object();
        readonly StreamWriter log;
        readonly ManualResetEventSlim outputEnded = new ManualResetEventSlim(false);
        readonly ManualResetEventSlim errorEnded = new ManualResetEventSlim(false);
        bool disposed, exitRecorded;
        volatile string driverError = "";
        public string WinDivertError { get { return driverError; } }
        public Process Process { get; private set; }
        public string LogPath { get; private set; }
        public bool Initialized { get; private set; }

        public EngineSession(string executable, string arguments, string directory, string logPath)
        {
            LogPath = logPath;
            Directory.CreateDirectory(Path.GetDirectoryName(logPath));
            log = new StreamWriter(new FileStream(logPath, FileMode.Append, FileAccess.Write, FileShare.ReadWrite), new UTF8Encoding(false));
            log.AutoFlush = true;
            Write("START", executable + " " + arguments);
            Process = new Process();
            Process.StartInfo = new ProcessStartInfo(executable, arguments);
            Process.StartInfo.WorkingDirectory = directory;
            Process.StartInfo.UseShellExecute = false;
            // Keep the parent's console lifetime, while all native output goes to the log.
            Process.StartInfo.CreateNoWindow = false;
            Process.StartInfo.RedirectStandardInput = true;
            Process.StartInfo.RedirectStandardOutput = true;
            Process.StartInfo.RedirectStandardError = true;
            Process.StartInfo.StandardOutputEncoding = new UTF8Encoding(false);
            Process.StartInfo.StandardErrorEncoding = new UTF8Encoding(false);
            Process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e) {
                if (e.Data == null) { outputEnded.Set(); return; }
                if (e.Data.IndexOf("windivert initialized", StringComparison.OrdinalIgnoreCase) >= 0) Initialized = true;
                ObserveDriverError(e.Data);
                Write("OUT", e.Data);
            };
            Process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e) {
                if (e.Data == null) { errorEnded.Set(); return; }
                ObserveDriverError(e.Data);
                Write("ERR", e.Data);
            };
            try {
                if (!Process.Start()) throw new InvalidOperationException("winws2 did not start.");
                Process.BeginOutputReadLine();
                Process.BeginErrorReadLine();
            }
            catch (Exception error) { Write("START_ERROR", error.ToString()); Dispose(); throw; }
        }

        void ObserveDriverError(string message)
        {
            if (message != null && message.IndexOf("windivert", StringComparison.OrdinalIgnoreCase) >= 0 &&
                (message.IndexOf("error", StringComparison.OrdinalIgnoreCase) >= 0 || message.IndexOf("failed", StringComparison.OrdinalIgnoreCase) >= 0)) driverError = message;
        }
        public void DrainOutput()
        {
            if (Process.HasExited) { outputEnded.Wait(1000); errorEnded.Wait(1000); }
        }
        public void RecordStartup(string message) { Write("STARTUP", message); }

        void Write(string kind, string message)
        {
            lock (sync) {
                if (!disposed) log.WriteLine(DateTime.UtcNow.ToString("o") + " [" + kind + "] " + message);
            }
        }

        public void Stop()
        {
            if (Process == null) return;
            try {
                bool requested = false;
                if (!Process.HasExited) {
                    requested = true;
                    Process.Kill();
                    if (!Process.WaitForExit(5000)) throw new TimeoutException("winws2 did not stop within 5 seconds.");
                }
                outputEnded.Wait(1000);
                errorEnded.Wait(1000);
                lock (sync) {
                    if (!exitRecorded) {
                        Write("EXIT", "PID=" + Process.Id + "; Code=" + EngineStartupPolicy.FormatExit(Process.ExitCode) +
                              "; stop_requested=" + requested.ToString().ToLowerInvariant());
                        exitRecorded = true;
                    }
                }
            }
            catch (InvalidOperationException) { /* Start failed before a process existed. */ }
        }

        public void Dispose()
        {
            if (disposed) return;
            Stop();
            lock (sync) {
                if (disposed) return;
                disposed = true;
                log.Dispose();
            }
            if (Process != null) Process.Dispose();
            // Late native callbacks may still signal these events: do not dispose them here.
        }
    }

    // Bind sockets before constructing the filter. The registry prevents another recipe from
    // acquiring any port in this filter, including ports of requests that have already ended.
    public sealed class ProbePortLease : IDisposable
    {
        readonly object sync = new object();
        static readonly object registrySync = new object();
        static readonly HashSet<int> reserved = new HashSet<int>();
        readonly Queue<TcpClient> available = new Queue<TcpClient>();
        readonly List<TcpClient> owned = new List<TcpClient>();
        readonly int[] ports;
        bool disposed, aborted;
        public int[] Ports { get { return (int[])ports.Clone(); } }
        public ProbePortLease(int count)
        {
            if (count < 8 || count > 256) throw new ArgumentOutOfRangeException("count");
            ports = new int[count];
            try {
                for (int index = 0; index < count; index++) {
                    TcpClient client = new TcpClient(AddressFamily.InterNetwork);
                    try {
                        client.ExclusiveAddressUse = true;
                        client.Client.Bind(new IPEndPoint(IPAddress.Any, 0));
                        int port = ((IPEndPoint)client.Client.LocalEndPoint).Port;
                        lock (registrySync) {
                            if (!reserved.Add(port)) { client.Close(); index--; continue; }
                            ports[index] = port;
                        }
                        owned.Add(client);
                        available.Enqueue(client);
                    }
                    catch { client.Close(); throw; }
                }
            }
            catch { Dispose(); throw; }
        }
        internal TcpClient Rent()
        {
            lock (sync) {
                if (disposed || aborted) throw new OperationCanceledException("Probe source-port lease was closed.");
                if (available.Count == 0) throw new IOException("Reserved probe source ports exhausted; no unfiltered connection will be used.");
                return available.Dequeue();
            }
        }
        internal static void CloseSocket(TcpClient client)
        {
            if (client == null) return;
            try { Socket socket = client.Client; if (socket != null) socket.Close(0); }
            catch (SocketException) { }
            catch (ObjectDisposedException) { }
            try { client.Close(); } catch (ObjectDisposedException) { }
        }
        public void Abort()
        {
            lock (sync) {
                if (disposed || aborted) return;
                aborted = true;
                foreach (TcpClient client in owned) CloseSocket(client);
                available.Clear();
            }
        }
        public void Dispose()
        {
            lock (sync) {
                if (disposed) return;
                Abort();
                disposed = true;
                lock (registrySync) { foreach (int port in ports) if (port != 0) reserved.Remove(port); }
                available.Clear();
            }
        }
    }

    internal sealed class HttpConnection : IDisposable
    {
        TcpClient client;
        bool leased;
        SslStream stream;
        CancellationToken cancellation;
        Task pendingIO;
        readonly byte[] readBuffer = new byte[4096];
        int readPosition, readLength;
        CancellationTokenRegistration registration;
        readonly Dictionary<string, string> headers = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        long remaining = -1, chunkRemaining;
        bool chunked, chunkNeedsCRLF, ended;
        int headerBytes;
        public int Status { get; private set; }
        public string RemoteIP { get; private set; }
        public int SourcePort { get; private set; }
        public string Header(string key) { string value; return headers.TryGetValue(key, out value) ? value : ""; }
        static void Await(Task task, CancellationToken token)
        {
            try {
                while (!task.IsCompleted) { token.ThrowIfCancellationRequested(); Thread.Sleep(15); }
                token.ThrowIfCancellationRequested();
                task.GetAwaiter().GetResult();
            }
            catch {
                if (!task.IsCompleted) task.ContinueWith(delegate(Task failed) { var observed = failed.Exception; }, TaskContinuationOptions.OnlyOnFaulted);
                throw;
            }
        }
        void AwaitIO(Task task)
        {
            pendingIO = task;
            Await(task, cancellation);
            pendingIO = null;
        }
        int ReadWire(byte[] buffer, int offset, int count)
        {
            cancellation.ThrowIfCancellationRequested();
            Task<int> read = stream.ReadAsync(buffer, offset, count, cancellation);
            AwaitIO(read);
            return read.GetAwaiter().GetResult();
        }
        int ReadWireByte()
        {
            if (readPosition >= readLength) {
                readLength = ReadWire(readBuffer, 0, readBuffer.Length); readPosition = 0;
                if (readLength == 0) return -1;
            }
            return readBuffer[readPosition++];
        }
        public static HttpConnection Open(Uri uri, int timeout, CancellationToken token, ProbePortLease lease, string sourceAddress)
        {
            HttpConnection connection = new HttpConnection();
            connection.leased = lease != null;
            connection.cancellation = token;
            try {
                Task<IPAddress[]> dns = Dns.GetHostAddressesAsync(uri.DnsSafeHost);
                Await(dns, token);
                Exception last = null;
                foreach (IPAddress address in dns.Result) {
                    if (address.AddressFamily != AddressFamily.InterNetwork) continue;
                    token.ThrowIfCancellationRequested();
                    TcpClient candidate = lease == null ? new TcpClient(AddressFamily.InterNetwork) : lease.Rent();
                    try {
                        if (lease == null && !String.IsNullOrEmpty(sourceAddress)) candidate.Client.Bind(new IPEndPoint(IPAddress.Parse(sourceAddress), 0));
                        using (token.Register(delegate { ProbePortLease.CloseSocket(candidate); })) {
                            Task connecting = candidate.ConnectAsync(address, uri.Port);
                            Stopwatch wait = Stopwatch.StartNew();
                            while (!connecting.IsCompleted && wait.ElapsedMilliseconds < 5000) {
                                token.ThrowIfCancellationRequested(); Thread.Sleep(20);
                            }
                            if (!connecting.IsCompleted) {
                                connecting.ContinueWith(delegate(Task task) { var observed = task.Exception; }, TaskContinuationOptions.OnlyOnFaulted);
                                throw new TimeoutException("IPv4 TCP connect timeout.");
                            }
                            Await(connecting, token);
                        }
                        connection.client = candidate;
                        connection.RemoteIP = address.ToString();
                        connection.SourcePort = ((IPEndPoint)candidate.Client.LocalEndPoint).Port;
                        break;
                    }
                    catch (Exception error) { ProbePortLease.CloseSocket(candidate); last = error; token.ThrowIfCancellationRequested(); }
                }
                if (connection.client == null) throw new IOException("No reachable IPv4 address.", last);
                connection.registration = token.Register(delegate { ProbePortLease.CloseSocket(connection.client); });
                // No certificate callback: the OS validates both the chain and the DNS name.
                connection.stream = new SslStream(connection.client.GetStream(), connection.leased);
                connection.stream.ReadTimeout = timeout;
                connection.stream.WriteTimeout = timeout;
                connection.AwaitIO(connection.stream.AuthenticateAsClientAsync(uri.DnsSafeHost, null, SslProtocols.None, false));
                token.ThrowIfCancellationRequested();
                string path = String.IsNullOrEmpty(uri.PathAndQuery) ? "/" : uri.PathAndQuery;
                string host = uri.IsDefaultPort ? uri.DnsSafeHost : uri.Authority;
                string request = "GET " + path + " HTTP/1.1\r\nHost: " + host +
                    "\r\nUser-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/147.0.0.0 Safari/537.36" +
                    "\r\nAccept: text/html,application/xhtml+xml\r\nAccept-Encoding: identity\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n";
                byte[] bytes = Encoding.ASCII.GetBytes(request);
                connection.AwaitIO(connection.stream.WriteAsync(bytes, 0, bytes.Length, token));
                connection.AwaitIO(connection.stream.FlushAsync(token));
                connection.ReadHeaders();
                return connection;
            }
            catch { connection.Dispose(); throw; }
        }
        string ReadLine()
        {
            using (MemoryStream line = new MemoryStream()) {
                while (true) {
                    int value = ReadWireByte();
                    if (value < 0) throw new EndOfStreamException("Incomplete HTTP headers or chunk framing.");
                    if (++headerBytes > 65536 || line.Length > 8192) throw new IOException("HTTP headers or chunk framing too large.");
                    if (value == 10) return Encoding.ASCII.GetString(line.ToArray()).TrimEnd('\r');
                    line.WriteByte((byte)value);
                }
            }
        }
        void ReadHeaders()
        {
            string status = ReadLine();
            Match match = Regex.Match(status, @"^HTTP/1\.[01] +([0-9]{3})(?: |$)");
            if (!match.Success) throw new IOException("Invalid HTTP/1 response.");
            Status = Int32.Parse(match.Groups[1].Value);
            string line;
            while ((line = ReadLine()).Length > 0) {
                int colon = line.IndexOf(':');
                if (colon < 1) throw new IOException("Malformed HTTP header.");
                string name = line.Substring(0, colon).Trim(), value = line.Substring(colon + 1).Trim();
                if (headers.ContainsKey(name)) headers[name] += "," + value;
                else headers.Add(name, value);
            }
            string transfer = Header("Transfer-Encoding");
            if (!String.IsNullOrEmpty(transfer)) {
                if (!transfer.Equals("chunked", StringComparison.OrdinalIgnoreCase)) throw new IOException("Unsupported Transfer-Encoding.");
                chunked = true;
            }
            else if (!String.IsNullOrEmpty(Header("Content-Length"))) {
                if (!Int64.TryParse(Header("Content-Length"), out remaining) || remaining < 0) throw new IOException("Invalid Content-Length.");
            }
        }
        public int ReadBody(byte[] buffer, int count)
        {
            if (ended || (!chunked && remaining == 0)) return 0;
            if (chunked) {
                if (chunkRemaining == 0) {
                    if (chunkNeedsCRLF && ReadLine() != "") throw new IOException("Invalid HTTP chunk ending.");
                    string length = ReadLine().Split(';')[0].Trim();
                    if (!Int64.TryParse(length, System.Globalization.NumberStyles.AllowHexSpecifier, System.Globalization.CultureInfo.InvariantCulture, out chunkRemaining) || chunkRemaining < 0)
                        throw new IOException("Invalid HTTP chunk size.");
                    if (chunkRemaining == 0) { ended = true; return 0; }
                    chunkNeedsCRLF = true;
                }
                count = (int)Math.Min(count, chunkRemaining);
            }
            else if (remaining >= 0) count = (int)Math.Min(count, remaining);
            int read;
            if (readPosition < readLength) {
                read = Math.Min(count, readLength - readPosition);
                Buffer.BlockCopy(readBuffer, readPosition, buffer, 0, read); readPosition += read;
            }
            else read = ReadWire(buffer, 0, count);
            if (read == 0 && ((chunked && chunkRemaining > 0) || remaining > 0)) throw new EndOfStreamException("Incomplete response body.");
            if (chunked) chunkRemaining -= read;
            else if (remaining >= 0) remaining -= read;
            return read;
        }
        public void Dispose()
        {
            // Closing the underlying socket also interrupts a stalled TLS handshake/header/body.
            ProbePortLease.CloseSocket(client);
            registration.Dispose();
            if (stream != null) {
                SslStream ownedStream = stream;
                if (pendingIO != null && !pendingIO.IsCompleted) {
                    // A platform TLS operation may finish later, but its socket is already closed.
                    // It cannot send a request or migrate to the following recipe.
                    pendingIO.ContinueWith(delegate(Task done) {
                        var observed = done.Exception;
                        try { ownedStream.Dispose(); } catch (IOException) { } catch (ObjectDisposedException) { }
                    });
                }
                else ownedStream.Dispose();
            }
        }
    }

    public sealed class ProbeResult
    {
        public bool Success { get; set; }
        public bool ThresholdReached { get; set; }
        public bool PageSignature { get; set; }
        public int HttpStatus { get; set; }
        public long Bytes { get; set; }
        public double Seconds { get; set; }
        public string FinalUrl { get; set; }
        public string RemoteIP { get; set; }
        public int SourcePort { get; set; }
        public string ContentType { get; set; }
        public string ContentEncoding { get; set; }
        public string Reason { get; set; }
        public string Error { get; set; }
    }

    public sealed class YoutubeProbe : IDisposable
    {
        readonly CancellationTokenSource cancellation = new CancellationTokenSource();
        int disposed;
        public Task<ProbeResult> Task { get; private set; }

        public YoutubeProbe(string url, string allowedHost, int threshold, int timeoutMilliseconds)
            : this(url, allowedHost, threshold, timeoutMilliseconds, null, null) { }

        public YoutubeProbe(string url, string allowedHost, int threshold, int timeoutMilliseconds, ProbePortLease lease)
            : this(url, allowedHost, threshold, timeoutMilliseconds, lease, null) { }

        public YoutubeProbe(string url, string allowedHost, int threshold, int timeoutMilliseconds, ProbePortLease lease, string sourceAddress)
        {
            if (threshold < 1024 || threshold > 1048576) throw new ArgumentOutOfRangeException("threshold");
            if (timeoutMilliseconds < 1000 || timeoutMilliseconds > 120000) throw new ArgumentOutOfRangeException("timeoutMilliseconds");
            cancellation.CancelAfter(timeoutMilliseconds);
            Task = System.Threading.Tasks.Task.Run<ProbeResult>(delegate {
                return Run(url, allowedHost, threshold, timeoutMilliseconds, cancellation.Token, lease, sourceAddress);
            });
        }

        public void Cancel() { try { cancellation.Cancel(); } catch (ObjectDisposedException) { } }
        public void Dispose()
        {
            if (Interlocked.Exchange(ref disposed, 1) != 0) return;
            Cancel();
            // Dispose the source only once its callbacks and the worker have ended.
            if (Task.IsCompleted) cancellation.Dispose();
            else Task.ContinueWith(delegate { cancellation.Dispose(); });
        }

        public static bool Allowed(Uri uri, string allowedHost)
        {
            if (uri.Scheme != "https" || !String.IsNullOrEmpty(uri.UserInfo)) return false;
            string host = uri.DnsSafeHost.ToLowerInvariant();
            if (String.Equals(allowedHost, "www.youtube.com", StringComparison.OrdinalIgnoreCase))
                return host == "www.youtube.com" || host == "youtube.com" || host == "m.youtube.com";
            // The explicit host is useful to exercise the same transport against a local TLS fixture.
            // The product always passes www.youtube.com, with no user-controlled URL.
            return String.Equals(host, allowedHost, StringComparison.OrdinalIgnoreCase);
        }

        public static string DecodePrefix(byte[] bytes, string encoding)
        {
            if (String.IsNullOrEmpty(encoding) || encoding.Equals("identity", StringComparison.OrdinalIgnoreCase))
                return Encoding.UTF8.GetString(bytes);
            using (MemoryStream source = new MemoryStream(bytes)) {
                Stream decoder;
                if (encoding.Equals("gzip", StringComparison.OrdinalIgnoreCase)) decoder = new GZipStream(source, CompressionMode.Decompress);
                else if (encoding.Equals("deflate", StringComparison.OrdinalIgnoreCase)) decoder = new DeflateStream(source, CompressionMode.Decompress);
                else return null;
                using (decoder)
                using (MemoryStream decoded = new MemoryStream()) {
                    byte[] buffer = new byte[4096];
                    try {
                        int count;
                        while (decoded.Length < 1048576 && (count = decoder.Read(buffer, 0, (int)Math.Min(buffer.Length, 1048576 - decoded.Length))) > 0)
                            decoded.Write(buffer, 0, count);
                    }
                    catch (IOException) { /* A 100 KiB prefix may end before the gzip footer. */ }
                    return Encoding.UTF8.GetString(decoded.ToArray());
                }
            }
        }

        public static bool IsYoutubeHtml(string html)
        {
            if (String.IsNullOrEmpty(html)) return false;
            string text = html.ToLowerInvariant();
            if (!Regex.IsMatch(text, @"<!doctype\s+html|<html\b")) return false;
            bool bootstrap = text.Contains("ytcfg.set") || text.Contains("ytinitialdata") || text.Contains("<ytd-app");
            bool identity = text.Contains("innertube_") || Regex.IsMatch(text, @"<title[^>]*>[^<]*youtube");
            return bootstrap && identity;
        }

        public static bool IsChallenge(string html)
        {
            return Regex.IsMatch(html ?? "", @"(?is)<(?:form|div)[^>]*(?:id|class)\s*=\s*['"" ][^>]*\b(?:g-recaptcha|captcha-form)\b|<form[^>]*action\s*=\s*['""][^'""]*(?:/sorry/|consent\.google\.)");
        }

        static ProbeResult Run(string url, string allowedHost, int threshold, int timeout, CancellationToken token, ProbePortLease lease, string sourceAddress)
        {
            ProbeResult result = new ProbeResult { Reason = "NOT_STARTED", FinalUrl = url, ContentType = "", ContentEncoding = "", Error = "" };
            Stopwatch timer = Stopwatch.StartNew();
            try {
                Uri current = new Uri(url);
                for (int redirect = 0; redirect <= 3; redirect++) {
                    token.ThrowIfCancellationRequested();
                    result.FinalUrl = current.AbsoluteUri;
                    if (!Allowed(current, allowedHost)) { result.Reason = "UNEXPECTED_FINAL_DOMAIN"; return result; }
                    using (HttpConnection connection = HttpConnection.Open(current, timeout, token, lease, sourceAddress)) {
                        result.RemoteIP = connection.RemoteIP;
                        result.SourcePort = connection.SourcePort;
                        result.HttpStatus = connection.Status;
                        if (result.HttpStatus >= 300 && result.HttpStatus <= 399 && result.HttpStatus != 304) {
                            string location = connection.Header("Location");
                            if (String.IsNullOrEmpty(location)) { result.Reason = "REDIRECT_WITHOUT_LOCATION"; return result; }
                            current = new Uri(current, location);
                            continue;
                        }
                        if (result.HttpStatus != 200 && result.HttpStatus != 206) { result.Reason = "HTTP_STATUS"; return result; }
                        result.ContentType = connection.Header("Content-Type");
                        result.ContentEncoding = connection.Header("Content-Encoding");
                        if (result.ContentType.IndexOf("text/html", StringComparison.OrdinalIgnoreCase) < 0 &&
                            result.ContentType.IndexOf("application/xhtml+xml", StringComparison.OrdinalIgnoreCase) < 0) {
                            result.Reason = "NOT_HTML"; return result;
                        }
                        using (MemoryStream body = new MemoryStream(threshold)) {
                            byte[] buffer = new byte[8192];
                            while (result.Bytes < threshold) {
                                token.ThrowIfCancellationRequested();
                                int count = connection.ReadBody(buffer, (int)Math.Min(buffer.Length, threshold - result.Bytes));
                                if (count == 0) break;
                                body.Write(buffer, 0, count);
                                result.Bytes += count;
                            }
                            result.ThresholdReached = result.Bytes >= threshold;
                            string html = DecodePrefix(body.ToArray(), result.ContentEncoding);
                            if (html == null) { result.Reason = "UNSUPPORTED_CONTENT_ENCODING"; return result; }
                            if (IsChallenge(html)) { result.Reason = "CAPTCHA_OR_CONSENT"; return result; }
                            result.PageSignature = IsYoutubeHtml(html);
                            if (!result.PageSignature) { result.Reason = "NOT_YOUTUBE_HTML"; return result; }
                            result.Success = result.ThresholdReached;
                            result.Reason = result.Success ? "THRESHOLD_REACHED" : "SHORT_COMPLETE_RESPONSE";
                            return result;
                        }
                    }
                }
                result.Reason = "TOO_MANY_REDIRECTS";
            }
            catch (OperationCanceledException) { result.Reason = "CANCELLED_OR_TIMEOUT"; }
            catch (Exception error) { result.Reason = token.IsCancellationRequested ? "CANCELLED_OR_TIMEOUT" : "TRANSFER_ERROR"; result.Error = error.Message; }
            finally { result.Seconds = Math.Round(timer.Elapsed.TotalSeconds, 3); }
            return result;
        }
    }
    public sealed class YoutubeScanControl : IDisposable
    {
        readonly object sync = new object();
        readonly List<YoutubeRecipeCheck> workers = new List<YoutubeRecipeCheck>();
        readonly Thread reader;
        volatile bool stopping;
        int signal;
        public string Signal { get { int value = Interlocked.CompareExchange(ref signal, 0, 0); return value == 2 ? "Stop" : value == 1 ? "Escape" : ""; } }
        public string ReaderError { get; private set; }
        public YoutubeScanControl(bool keyboardAvailable)
        {
            ReaderError = "";
            if (keyboardAvailable) {
                reader = new Thread(ReadKeys); reader.IsBackground = true; reader.Name = "AntiDPI YouTube keys"; reader.Start();
            }
        }
        void ReadKeys()
        {
            try {
                while (!stopping) {
                    if (Console.KeyAvailable) {
                        ConsoleKeyInfo key = Console.ReadKey(true);
                        if (key.Key == ConsoleKey.Escape) Request(false);
                        else if (key.KeyChar == 3 || (key.Key == ConsoleKey.C && (key.Modifiers & ConsoleModifiers.Control) != 0)) Request(true);
                    }
                    Thread.Sleep(20);
                }
            }
            catch (Exception error) { ReaderError = error.Message; }
        }
        public void Register(YoutubeRecipeCheck worker)
        {
            bool cancel;
            lock (sync) { cancel = stopping || Signal.Length != 0; if (!cancel) workers.Add(worker); }
            if (cancel) worker.Cancel();
        }
        public void Unregister(YoutubeRecipeCheck worker) { lock (sync) workers.Remove(worker); }
        public void Request(bool stopProgram)
        {
            if (stopProgram) Interlocked.Exchange(ref signal, 2);
            else Interlocked.CompareExchange(ref signal, 1, 0);
            YoutubeRecipeCheck[] active;
            lock (sync) active = workers.ToArray();
            foreach (YoutubeRecipeCheck worker in active) worker.Cancel();
        }
        public void Dispose()
        {
            stopping = true;
            if (reader != null && reader != Thread.CurrentThread && !reader.Join(2000))
                throw new TimeoutException("Console key reader did not stop; input cannot return to the menu yet.");
            lock (sync) workers.Clear();
        }
    }

    public sealed class YoutubeRecipePlan
    {
        public int Number { get; set; }
        public string Executable { get; set; }
        public string Directory { get; set; }
        public string PreflightArguments { get; set; }
        public string EngineArguments { get; set; }
        public string NativeLog { get; set; }
        public string RecordPath { get; set; }
        public ProbePortLease Ports { get; set; }
        public string Url { get; set; }
        public string AllowedHost { get; set; }
        public int Threshold { get; set; }
        public int TimeoutMilliseconds { get; set; }
        public int WarmupMilliseconds { get; set; }
        public int Attempts { get; set; }
        public YoutubeRecipePlan()
        {
            Url = "https://www.youtube.com/"; AllowedHost = "www.youtube.com";
            Threshold = 102400; TimeoutMilliseconds = 15000; WarmupMilliseconds = 1000; Attempts = 2;
        }
    }

    public sealed class YoutubeRecipeResult
    {
        public int Number { get; set; }
        public int Successes { get; set; }
        public ProbeResult[] Attempts { get; set; }
        public bool Cancelled { get; set; }
        public bool DriverFailure { get; set; }
        public string DriverError { get; set; }
        public string Error { get; set; }
        public string CleanupError { get; set; }
        public DateTime CompletedUtc { get; set; }
    }

    public sealed class YoutubeRecipeCheck : IDisposable
    {
        readonly object sync = new object();
        readonly CancellationTokenSource cancellation = new CancellationTokenSource();
        readonly YoutubeRecipePlan plan;
        YoutubeProbe currentProbe;
        WinDivertHealthMonitor driverHealth;
        bool disposed;
        public Task<YoutubeRecipeResult> Task { get; private set; }
        public int Number { get { return plan.Number; } }
        public YoutubeRecipeCheck(YoutubeRecipePlan value)
        {
            if (value == null || value.Ports == null) throw new ArgumentException("An exclusive source-port lease is required.");
            plan = value;
            Task = System.Threading.Tasks.Task.Run<YoutubeRecipeResult>(delegate { return Run(); });
        }
        public void Cancel()
        {
            lock (sync) {
                if (disposed) return;
                cancellation.Cancel();
                plan.Ports.Abort();
                if (currentProbe != null) currentProbe.Cancel();
            }
        }
        static string Json(string value)
        {
            return "\"" + value.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "\\r").Replace("\n", "\\n") + "\"";
        }
        void SaveIdentity(Process process)
        {
            System.IO.Directory.CreateDirectory(Path.GetDirectoryName(plan.RecordPath));
            string start = process.StartTime.ToUniversalTime().ToString("o");
            string text = "{\"PID\":" + process.Id + ",\"Exe\":" + Json(plan.Executable) + ",\"StartUTC\":" + Json(start) + "}";
            File.WriteAllText(plan.RecordPath, text, new UTF8Encoding(false));
        }
        void CheckAlive(EngineSession engine)
        {
            cancellation.Token.ThrowIfCancellationRequested();
            if (engine.Process.HasExited) engine.DrainOutput();
            if (engine.WinDivertError.Length != 0) throw new WinDivertEngineException(engine.WinDivertError, plan.NativeLog);
            if (engine.Process.HasExited) throw new WinDivertEngineException("PROCESS_EXIT: " + engine.Process.ExitCode, plan.NativeLog);
            if (driverHealth != null) {
                string fault = driverHealth.Poll(DateTime.UtcNow);
                if (fault.Length != 0) {
                    WinDivertRecovery.Log(Path.Combine(Path.GetDirectoryName(plan.NativeLog), "WinDivert_recovery.log"), "DETECTED " + fault + "; " + driverHealth.LastState);
                    throw new WinDivertEngineException(fault, plan.NativeLog);
                }
            }
        }
        EngineSession StartChecked(bool preflight)
        {
            string stage = preflight ? "проверка параметров/Lua" : "запуск перехвата";
            for (int number = 1; number <= EngineStartupPolicy.MaxAttempts; number++) {
                cancellation.Token.ThrowIfCancellationRequested();
                EngineSession session = new EngineSession(plan.Executable,
                    preflight ? plan.PreflightArguments : plan.EngineArguments, plan.Directory, plan.NativeLog);
                bool ready = false, retry = false;
                try {
                    session.RecordStartup("Stage=" + stage + "; Attempt=" + number + "/" + EngineStartupPolicy.MaxAttempts);
                    Stopwatch wait = Stopwatch.StartNew();
                    if (preflight) {
                        while (!session.Process.WaitForExit(40)) {
                            cancellation.Token.ThrowIfCancellationRequested();
                            if (wait.ElapsedMilliseconds > 15000) throw new TimeoutException("winws2 parameter/Lua check timed out.");
                        }
                    }
                    else {
                        while (wait.ElapsedMilliseconds < plan.WarmupMilliseconds) {
                            cancellation.Token.ThrowIfCancellationRequested();
                            if (session.Process.WaitForExit(25)) break;
                        }
                    }
                    cancellation.Token.ThrowIfCancellationRequested();
                    if (preflight || session.Process.HasExited) {
                        session.DrainOutput();
                        int code = session.Process.ExitCode;
                        if (code != 0 && session.WinDivertError.Length != 0) throw new WinDivertEngineException(session.WinDivertError, plan.NativeLog);
                        if (!(preflight && code == 0)) {
                            if (!EngineStartupPolicy.IsDllInitFailure(code))
                                throw new IOException("winws2 " + stage + ": " + EngineStartupPolicy.FormatExit(code));
                            if (number == EngineStartupPolicy.MaxAttempts)
                                throw new NativeStartupException(stage, code, plan.NativeLog);
                            session.RecordStartup("RETRY: " + EngineStartupPolicy.FormatExit(code) +
                                "; delay_ms=" + EngineStartupPolicy.RetryDelayMilliseconds(number));
                            retry = true;
                            continue;
                        }
                    }
                    ready = true;
                    return session;
                }
                finally {
                    if (!ready) {
                        session.Dispose();
                        // Only DLL-initialization failures reach a new iteration.
                        // Cancellation interrupts the backoff as well as process warmup.
                        if (retry && cancellation.Token.WaitHandle.WaitOne(EngineStartupPolicy.RetryDelayMilliseconds(number)))
                            cancellation.Token.ThrowIfCancellationRequested();
                    }
                }
            }
            throw new IOException("winws2 startup attempts exhausted.");
        }
        YoutubeRecipeResult Run()
        {
            YoutubeRecipeResult result = new YoutubeRecipeResult { Number = plan.Number, Error = "", CleanupError = "" };
            List<ProbeResult> attempts = new List<ProbeResult>();
            EngineSession engine = null;
            try {
                cancellation.Token.ThrowIfCancellationRequested();
                engine = StartChecked(true);
                engine.Dispose();
                engine = null;
                cancellation.Token.ThrowIfCancellationRequested();
                engine = StartChecked(false);
                driverHealth = new WinDivertHealthMonitor(plan.Directory);
                SaveIdentity(engine.Process);
                for (int attempt = 0; attempt < plan.Attempts; attempt++) {
                    CheckAlive(engine);
                    YoutubeProbe probe;
                    lock (sync) {
                        cancellation.Token.ThrowIfCancellationRequested();
                        currentProbe = probe = new YoutubeProbe(plan.Url, plan.AllowedHost, plan.Threshold, plan.TimeoutMilliseconds, plan.Ports);
                    }
                    try {
                        while (!probe.Task.IsCompleted) { CheckAlive(engine); Thread.Sleep(25); }
                        ProbeResult response = probe.Task.GetAwaiter().GetResult();
                        attempts.Add(response);
                        if (response.Success) result.Successes++;
                        CheckAlive(engine);
                    }
                    finally {
                        lock (sync) { probe.Cancel(); currentProbe = null; }
                        try {
                            if (!probe.Task.Wait(3000)) {
                                plan.Ports.Abort();
                                probe.Cancel();
                                result.Error = "HTTPS_ABORTED: sockets closed; delayed platform TLS operation detached.";
                                throw new OperationCanceledException(result.Error);
                            }
                        }
                        catch (OperationCanceledException) { throw; }
                        catch (Exception error) { result.CleanupError = error.GetBaseException().Message; }
                        finally { probe.Dispose(); }
                        if (result.CleanupError.Length != 0) throw new IOException(result.CleanupError);
                    }
                }
            }
            catch (OperationCanceledException) { result.Cancelled = true; }
            catch (Exception error) {
                result.Cancelled = cancellation.IsCancellationRequested;
                result.Error = error.GetBaseException().Message;
                WinDivertEngineException driverFailure = error as WinDivertEngineException;
                result.DriverFailure = driverFailure != null;
                result.DriverError = driverFailure == null ? "" : driverFailure.DriverError;
            }
            finally {
                try { if (engine != null) engine.Dispose(); }
                catch (Exception error) { result.CleanupError = error.GetBaseException().Message; }
                // Preserve a PID record if cleanup failed; never overwrite another slot's record.
                if (result.CleanupError.Length == 0) {
                    try { if (File.Exists(plan.RecordPath)) File.Delete(plan.RecordPath); }
                    catch (Exception error) { result.CleanupError = error.Message; }
                }
                plan.Ports.Dispose();
                result.Attempts = attempts.ToArray();
                result.CompletedUtc = DateTime.UtcNow;
            }
            return result;
        }
        public void Dispose()
        {
            if (disposed) return;
            Cancel();
            // Cancellation closes the active TLS socket and the worker stops its own engine.
            if (!Task.Wait(12000)) throw new TimeoutException("YouTube worker did not stop; a new strategy must not start.");
            YoutubeRecipeResult result = Task.GetAwaiter().GetResult();
            if (!String.IsNullOrEmpty(result.CleanupError)) throw new IOException("YouTube worker cleanup failed: " + result.CleanupError);
            lock (sync) { if (!disposed) { disposed = true; cancellation.Dispose(); } }
        }
    }

}
