// Copyright Igor Krauch (github.com/igareck).
// Stream output retains native line-wrap metadata for console resizing.
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace Igareck {
    public static class ConsoleArtworkCLI {
        [StructLayout(LayoutKind.Sequential)] public struct Coord {
            public short X,Y;public Coord(short x,short y){X=x;Y=y;}
        }
        [StructLayout(LayoutKind.Sequential)] public struct SmallRect {public short Left,Top,Right,Bottom;}
        [StructLayout(LayoutKind.Sequential)] public struct BufferInfo {
            public Coord Size,Cursor;public ushort Attributes;public SmallRect Window;public Coord Maximum;
        }
        [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] public struct FontInfo {
            public uint Size,Index;public Coord Cell;public uint Family,Weight;
            [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)] public string Face;
        }
        [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int kind);
        [DllImport("kernel32.dll")] static extern bool GetConsoleMode(IntPtr h,out uint mode);
        [DllImport("kernel32.dll")] static extern bool SetConsoleMode(IntPtr h,uint mode);
        [DllImport("kernel32.dll")] static extern bool GetConsoleScreenBufferInfo(IntPtr h,out BufferInfo info);
        [DllImport("kernel32.dll")] static extern bool SetConsoleTextAttribute(IntPtr h,ushort attributes);
        [DllImport("kernel32.dll",CharSet=CharSet.Unicode,ExactSpelling=true)] static extern bool WriteConsoleW(IntPtr h,string value,uint length,out uint written,IntPtr reserved);
        [DllImport("kernel32.dll",CharSet=CharSet.Unicode,ExactSpelling=true)] static extern bool GetCurrentConsoleFontEx(IntPtr h,bool maximum,ref FontInfo font);
        [DllImport("kernel32.dll",CharSet=CharSet.Unicode,ExactSpelling=true)] static extern bool SetCurrentConsoleFontEx(IntPtr h,bool maximum,ref FontInfo font);
        [DllImport("kernel32.dll")] static extern Coord GetLargestConsoleWindowSize(IntPtr h);
        [DllImport("kernel32.dll")] static extern bool SetConsoleScreenBufferSize(IntPtr h,Coord size);
        [DllImport("kernel32.dll")] static extern bool SetConsoleWindowInfo(IntPtr h,bool absolute,ref SmallRect rectangle);
        [DllImport("kernel32.dll")] static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll",CharSet=CharSet.Unicode,ExactSpelling=true)] static extern IntPtr SendMessageTimeoutW(IntPtr window,uint message,IntPtr wParam,IntPtr lParam,uint flags,uint timeout,out UIntPtr result);
        [DllImport("gdi32.dll",CharSet=CharSet.Unicode,ExactSpelling=true)] static extern int AddFontResourceExW(string path,uint flags,IntPtr reserved);
        [DllImport("gdi32.dll",CharSet=CharSet.Unicode,ExactSpelling=true)] static extern bool RemoveFontResourceExW(string path,uint flags,IntPtr reserved);
        [DllImport("gdi32.dll")] static extern IntPtr CreateCompatibleDC(IntPtr dc);
        [DllImport("gdi32.dll")] static extern bool DeleteDC(IntPtr dc);
        [DllImport("gdi32.dll")] static extern bool DeleteObject(IntPtr obj);
        [DllImport("gdi32.dll")] static extern IntPtr SelectObject(IntPtr dc,IntPtr obj);
        [DllImport("gdi32.dll",CharSet=CharSet.Unicode,ExactSpelling=true)] static extern IntPtr CreateFontW(int height,int width,int escape,int orientation,int weight,uint italic,uint underline,uint strike,uint charset,uint precision,uint clipping,uint quality,uint pitch,string face);
        [DllImport("gdi32.dll",CharSet=CharSet.Unicode,ExactSpelling=true)] static extern uint GetGlyphIndicesW(IntPtr dc,string text,int count,[Out] ushort[] glyphs,uint flags);
        [DllImport("gdi32.dll",CharSet=CharSet.Unicode,ExactSpelling=true)] static extern int GetTextFaceW(IntPtr dc,int count,StringBuilder face);
        const string Family="Igareck Art CLI2";
        static FontInfo originalFont;static bool haveOriginal;
        static string addedFont,temporaryDirectory;
        static IntPtr Output {get{return GetStdHandle(-11);}}

        static void RefreshFonts() {
            IntPtr window=GetConsoleWindow();
            if(window!=IntPtr.Zero){UIntPtr result;SendMessageTimeoutW(window,0x001d,IntPtr.Zero,IntPtr.Zero,2,500,out result);}
        }
        static bool HasGlyphs(int count) {
            if(count<1 || count>0x1900)return false;
            IntPtr dc=CreateCompatibleDC(IntPtr.Zero);if(dc==IntPtr.Zero)return false;
            IntPtr font=CreateFontW(16,0,0,0,400,0,0,0,1,7,0,0,0,Family);
            if(font==IntPtr.Zero){DeleteDC(dc);return false;}
            IntPtr previous=SelectObject(dc,font);
            try {
                StringBuilder family=new StringBuilder(64);GetTextFaceW(dc,64,family);
                if(!String.Equals(family.ToString(),Family,StringComparison.OrdinalIgnoreCase))return false;
                char[] text=new char[count];for(int i=0;i<count;i++)text[i]=(char)(0xe000+i);
                ushort[] glyphs=new ushort[count];
                if(GetGlyphIndicesW(dc,new string(text),count,glyphs,1)==UInt32.MaxValue)return false;
                foreach(ushort glyph in glyphs)if(glyph==0 || glyph==0xffff)return false;
                return true;
            } finally {SelectObject(dc,previous);DeleteObject(font);DeleteDC(dc);}
        }
        public static bool PrepareFont(string path,int glyphCount) {
            if(addedFont!=null)return HasGlyphs(glyphCount);
            FontInfo current=new FontInfo();current.Size=(uint)Marshal.SizeOf(typeof(FontInfo));
            if(!GetCurrentConsoleFontEx(Output,false,ref current))return false;
            originalFont=current;haveOriginal=true;
            if(!File.Exists(path))return false;
            temporaryDirectory=Path.Combine(Path.GetTempPath(),"IgareckArtwork_"+Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(temporaryDirectory);
            string copy=Path.Combine(temporaryDirectory,"IgareckArtCLI.ttf");File.Copy(path,copy,false);
            if(AddFontResourceExW(copy,0,IntPtr.Zero)<1){ReleaseFont();return false;}
            addedFont=copy;RefreshFonts();
            FontInfo chosen=current;chosen.Cell=new Coord(0,(short)Math.Max(16,(int)current.Cell.Y));
            chosen.Family=54;chosen.Weight=400;chosen.Face=Family;
            FontInfo actual=new FontInfo();actual.Size=(uint)Marshal.SizeOf(typeof(FontInfo));
            if(!SetCurrentConsoleFontEx(Output,false,ref chosen) || !GetCurrentConsoleFontEx(Output,false,ref actual)
               || actual.Cell.Y<chosen.Cell.Y || !String.Equals(actual.Face,Family,StringComparison.OrdinalIgnoreCase) || !HasGlyphs(glyphCount)){
                ReleaseFont();return false;
            }
            uint mode;if(GetConsoleMode(Output,out mode))SetConsoleMode(Output,(mode|3u|4u)&~8u);
            return true;
        }
        public static void ReleaseFont() {
            if(haveOriginal){SetCurrentConsoleFontEx(Output,false,ref originalFont);haveOriginal=false;}
            if(addedFont!=null){RemoveFontResourceExW(addedFont,0,IntPtr.Zero);addedFont=null;RefreshFonts();}
            if(temporaryDirectory!=null){
                try{Directory.Delete(temporaryDirectory,true);temporaryDirectory=null;}catch(IOException){}catch(UnauthorizedAccessException){}
            }
        }
        public static bool EnsureWidth(int columns,int minimumRows) {
            BufferInfo info;if(!GetConsoleScreenBufferInfo(Output,out info))return false;
            if(info.Window.Right-info.Window.Left+1>=columns)return true;
            Coord largest=GetLargestConsoleWindowSize(Output);if(largest.X<columns || largest.Y<1)return false;
            int rows=Math.Min(largest.Y,Math.Max(minimumRows,info.Window.Bottom-info.Window.Top+1));
            int bufferRows=Math.Min(32767,Math.Max(info.Size.Y,rows+minimumRows));
            if(!SetConsoleScreenBufferSize(Output,new Coord((short)Math.Max(info.Size.X,columns),(short)bufferRows)))return false;
            SmallRect window=new SmallRect();window.Left=0;window.Right=(short)(columns-1);
            window.Top=(short)Math.Max(0,Math.Min(info.Window.Top,bufferRows-rows));window.Bottom=(short)(window.Top+rows-1);
            return SetConsoleWindowInfo(Output,true,ref window);
        }
        static bool Write(string value) {
            while(value.Length>0){
                uint written;if(!WriteConsoleW(Output,value,(uint)value.Length,out written,IntPtr.Zero) || written==0 || written>value.Length)return false;
                value=value.Substring((int)written);
            }
            return true;
        }
        public static bool DrawRows(string[] rows,string[] colours) {
            if(rows==null || colours==null || rows.Length!=32 || colours.Length!=rows.Length)return false;
            foreach(string row in rows)if(row==null || row.Length!=100)return false;
            foreach(string row in colours)if(row==null || row.Length!=100)return false;
            BufferInfo before;if(!GetConsoleScreenBufferInfo(Output,out before) || before.Window.Right-before.Window.Left+1<101)return false;
            uint mode;if(!GetConsoleMode(Output,out mode) || !SetConsoleMode(Output,(mode|3u|4u)&~8u))return false;
            string[] palette={"255;255;255","212;186;50","96;190;112"};
            try {
                for(int y=0;y<rows.Length;y++){
                    if(!Write("\r"))return false;
                    for(int first=0;first<100;){
                        int colour=colours[y][first]-'0';if(colour<0 || colour>=palette.Length)return false;
                        int last=first+1;while(last<100 && colours[y][last]==colours[y][first])last++;
                        if(!Write("\x1b[38;2;"+palette[colour]+";48;2;12;12;12m"+rows[y].Substring(first,last-first)))return false;
                        first=last;
                    }
                    if(!Write("\x1b[0m"))return false;
                    SetConsoleTextAttribute(Output,before.Attributes);
                    if(!Write("\r\n"))return false;
                }
                return Write("\r\n");
            } finally {SetConsoleTextAttribute(Output,before.Attributes);SetConsoleMode(Output,mode);}
        }
    }
}
