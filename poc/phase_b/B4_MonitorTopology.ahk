#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Common.ahk

out := "Phase B-4 Monitor Topology PoC`n"
out .= "Timestamp: " PB_Now() "`n"
out .= "MonitorCount: " MonitorGetCount() "`n"
out .= "PrimaryMonitor: " MonitorGetPrimary() "`n`n"
out .= "Index`tPrimary`tL`tT`tR`tB`tW`tH`tWorkL`tWorkT`tWorkR`tWorkB`tWorkW`tWorkH`n"

count := MonitorGetCount()
Loop count {
    l := 0, t := 0, r := 0, b := 0
    wl := 0, wt := 0, wr := 0, wb := 0
    MonitorGet(A_Index, &l, &t, &r, &b)
    MonitorGetWorkArea(A_Index, &wl, &wt, &wr, &wb)
    out .= (
        A_Index "`t" (A_Index = MonitorGetPrimary() ? "1" : "0") "`t"
        l "`t" t "`t" r "`t" b "`t" (r-l) "`t" (b-t) "`t"
        wl "`t" wt "`t" wr "`t" wb "`t" (wr-wl) "`t" (wb-wt) "`n"
    )
}

path := PB_WriteLog("B4_monitor_topology.tsv", out)
MsgBox("B-4 complete.`n`nLog: " path)
