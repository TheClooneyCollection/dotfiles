---
name: avp-mvd-alvr-stutter-resolver
description: Audit and fix Apple Vision Pro streaming stutter for Mac Virtual Display (MVD) and ALVR: AWDL channel hopping, router channel and width, wired vs wireless paths, subnets and GPU encoder contention. Use when the user reports MVD or ALVR stutter, lag or drops on Vision Pro, asks which router channel or width to use for Vision Pro, wants their VR or MVD network checked, or mentions AWDL or channel hopping.
---

Apple devices share one radio between the router channel and AWDL (peer-to-peer, which MVD uses). When the two differ, the radio time-slices and streams stutter; a clean channel alone does not fix it. Audit the whole setup, not only the channel: run every step, then report each item as OK or as an issue with its fix, against the target layout below.

**Root commands.** Try `sudo -n <cmd>` first. If it wants a password, give the user one line to paste in a separate terminal that writes to an absolute path you can read (your scratchpad or temp dir), e.g. `sudo wdutil info > <dir>/wdutil.txt`, wait for "done", then read the file. Never ask for the password; `!`-prefixed in-session commands cannot take one either.

1. **Mac Wi-Fi link.** `system_profiler SPAirPortDataType`: channel, width, PHY mode, country code. Done: the Mac's channel and router are known.
2. **AWDL schedule (root).** `wdutil info`: Wi-Fi `Channel`, `CCA`, `RSSI`, `Noise`; AWDL `Channel Sequence`. Done: you know whether any slot differs from the router channel.
3. **Wired path.** `networksetup -listnetworkserviceorder` and `route -n get default`; Ethernet should come first. Done: you know whether Mac traffic takes the cable.
4. **Subnets.** Mac Ethernet, Mac Wi-Fi, the Vision Pro (ask the user: Settings > Wi-Fi > (i)) and the ALVR PC must share one subnet; discovery does not cross routers. Done: every IP is listed.
5. **MVD traffic.** `netstat -I llw0 -b` twice, a few seconds apart. MVD runs on `llw0`, not `awdl0`, at roughly 11 to 16 Mbps. Done: you know whether it is flowing.
6. **ALVR PC (Windows, over SSH if available).** Inline `powershell -Command` over ssh gets mangled by cmd.exe: write a `.ps1`, scp it, run it with `powershell -NoProfile -ExecutionPolicy Bypass -File`. Check IP and subnet, `nvidia-smi dmon -s u` (the `enc` column), and whether Parsec is running; Parsec and ALVR share NVENC, so close Parsec in VR. Done: encoder load and subnet are known.
7. **Neighbours.** If the channel choice is in question, ask for a Wi-Fi scanner screenshot taken in the play space. Done: each 80 MHz block's occupancy is known.
8. **Report.** Every item OK or issue plus fix. After a channel change, rerun step 2, then have the user retest MVD and ALVR; the radio check does not prove the stream. Done: the user has the list and the retest result, or knows the retest is pending.

## Target layout

- A dedicated router near the play space. The gaming PC and the Mac are wired to it, and the Vision Pro and the Mac's Wi-Fi are joined to it (this pins the Mac's radio to that channel even while Ethernet carries traffic). Everything is on one subnet.
- 5 GHz, 80 MHz, in a non-DFS block (36-48 or 149-161). Never use DFS (52-144) for VR, because radar events drop the network. Not 160 MHz. Ignore "best channel" picks of 165, which is 20 MHz only.
- Primary channel = the AWDL social channel from the sequence (44 in the UK, often 149 elsewhere), locked. Verified when step 2 shows every slot on one channel.
- A mixed wireless mode that includes 802.11ax; never suggest a mode without ax.

Example (UK): with the router on 36/80, the sequence was `36++ 36++ 44++ 44++ 36++ ...` (4 of 16 slots on 44). On 44/80, every slot was 44.
