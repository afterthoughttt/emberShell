using System;
using System.Runtime.InteropServices;
using System.Runtime.Intrinsics.X86;

public class CPUNative
{
    [DllImport("kernel32.dll")]
    private static extern uint GetSystemFirmwareTable(uint Provider, uint Table, byte[] Buffer, uint Size);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetLogicalProcessorInformationEx(uint Relationship, IntPtr Buffer, ref uint Length);

    private const uint RSMB = 0x52534D42;
    private const uint RelationProcessorCore = 0;

    public static uint GetBoostSpeedMHz()
    {
        if (X86Base.IsSupported)
        {
            var result = X86Base.CpuId(0x16, 0);
            uint max   = (uint)result.Item2 & 0xFFFF;
            uint base_ = (uint)result.Item1 & 0xFFFF;
            if (max   > 0) return max;
            if (base_ > 0) return base_;
        }

        return GetBoostFromSmbios();
    }

    private static uint GetBoostFromSmbios()
    {
        uint size = GetSystemFirmwareTable(RSMB, 0, null, 0);
        if (size == 0) return 0;

        byte[] buf = new byte[size];
        if (GetSystemFirmwareTable(RSMB, 0, buf, size) == 0) return 0;

        int pos = 5;
        while (pos < buf.Length)
        {
            byte type   = buf[pos];
            byte length = buf[pos + 1];

            if (type == 127) break;

            if (type == 4)
            {
                byte processorType = buf[pos + 0x05];
                byte status        = buf[pos + 0x18];
                if (processorType == 0x03 && (status & 0x07) == 1)
                    return (uint)(buf[pos + 0x14] | (buf[pos + 0x15] << 8));
            }

            int strPos = pos + length;
            while (strPos < buf.Length - 1)
            {
                if (buf[strPos] == 0 && buf[strPos + 1] == 0) { strPos += 2; break; }
                strPos++;
            }
            pos = strPos;
        }

        return 0;
    }

    public static uint GetPhysicalCores()
    {
        uint length = 0;
        GetLogicalProcessorInformationEx(RelationProcessorCore, IntPtr.Zero, ref length);

        IntPtr buf = Marshal.AllocHGlobal((int)length);
        try
        {
            if (!GetLogicalProcessorInformationEx(RelationProcessorCore, buf, ref length)) return 0;

            uint cores = 0;
            int pos = 0;
            while (pos < (int)length)
            {
                uint size = (uint)Marshal.ReadInt32(buf, pos + 4);
                cores++;
                pos += (int)size;
            }
            return cores;
        }
        finally
        {
            Marshal.FreeHGlobal(buf);
        }
    }
}