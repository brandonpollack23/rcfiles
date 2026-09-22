# Where you should look for a refresh
[Ars Technica, Baby](https://arstechnica.com/gadgets/2020/02/how-fast-are-your-disks-find-out-the-open-source-way-with-fio/)

# DS9 Drives
4x ZFS mirror strip configured Seagate Ironwolf drives, speed is supposed to max sequentiall at ~214 MB/s per drive

# Flags that matter when ZFS topology/cache changes.
`--fsync=1` -- Without a slog ZIL, good luck lol

# Example Write Runs

## Simple as pi, sequential and tough for the disk :(

```sh
fio --name=random-write --ioengine=posixaio --rw=randwrite --bs=4k --numjobs=1 --size=4g --iodepth=1 --runtime=60 --time_based --end_fsync=1
```
<details>
<summary>
DS9 reported these results:
WRITE: bw=380MiB/s (398MB/s), 380MiB/s-380MiB/s (398MB/s-398MB/s), io=26.0GiB (28.0GB), run=72774-72774msec
</summary>

```
random-write: (g=0): rw=randwrite, bs=(R) 128KiB-128KiB, (W) 128KiB-128KiB, (T) 128KiB-128KiB, ioengine=posixaio, iodepth=1
fio-3.12
Starting 1 process
random-write: Laying out IO file (1 file / 4096MiB)

random-write: (groupid=0, jobs=1): err= 0: pid=13924: Sat Mar 27 15:31:15 2021
  write: IOPS=3037, BW=380MiB/s (398MB/s)(26.0GiB/72774msec); 0 zone resets
    slat (nsec): min=1343, max=826919, avg=2698.76, stdev=2371.28
    clat (usec): min=22, max=1499, avg=268.36, stdev=89.67
     lat (usec): min=24, max=1507, avg=271.06, stdev=89.86
    clat percentiles (usec):
     |  1.00th=[   27],  5.00th=[   31], 10.00th=[  190], 20.00th=[  233],
     | 30.00th=[  260], 40.00th=[  273], 50.00th=[  277], 60.00th=[  281],
     | 70.00th=[  289], 80.00th=[  314], 90.00th=[  359], 95.00th=[  408],
     | 99.00th=[  502], 99.50th=[  529], 99.90th=[  570], 99.95th=[  611],
     | 99.99th=[  685]
   bw (  KiB/s): min=245504, max=2872320, per=100.00%, avg=471705.10, stdev=275497.13, samples=119
   iops        : min= 1918, max=22440, avg=3685.17, stdev=2152.32, samples=119
  lat (usec)   : 50=6.94%, 100=0.11%, 250=18.97%, 500=72.95%, 750=1.02%
  lat (usec)   : 1000=0.01%
  lat (msec)   : 2=0.01%
  cpu          : usr=1.39%, sys=0.57%, ctx=222008, majf=0, minf=44
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,221033,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=380MiB/s (398MB/s), 380MiB/s-380MiB/s (398MB/s-398MB/s), io=26.0GiB (28.0GB), run=72774-72774msec
```

</details>

## Ars simple single sequential

```sh
fio --name=random-write --ioengine=posixaio --rw=randwrite --bs=4k --size=4g --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1
```

## Ars 16 parallel 64KiB random write processes

This one is good for a NAS, simulations multiple users.

```sh
fio --name=random-write-parallel --ioengine=posixaio --rw=randwrite --bs=128k --size=256m --numjobs=16 --iodepth=16 --runtime=60 --time_based --end_fsync=1
```
<details>
<summary/>
DS9 Results: 

WRITE: bw=406MiB/s (426MB/s), 24.6MiB/s-27.8MiB/s (25.8MB/s-29.1MB/s), io=27.6GiB (29.7GB), run=63032-69712msec
</summary>

```
random-write-parallel: (g=0): rw=randwrite, bs=(R) 128KiB-128KiB, (W) 128KiB-128KiB, (T) 128KiB-128KiB, ioengine=posixaio, iodepth=16
...
fio-3.12
Starting 16 processes
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)
random-write-parallel: Laying out IO file (1 file / 256MiB)

random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1815: Sat Mar 27 15:35:26 2021
  write: IOPS=198, BW=24.8MiB/s (26.0MB/s)(1729MiB/69712msec); 0 zone resets
    slat (nsec): min=982, max=246460, avg=3033.21, stdev=3980.74
    clat (usec): min=724, max=162662, avg=69462.25, stdev=21532.41
     lat (usec): min=726, max=162664, avg=69465.28, stdev=21531.25
    clat percentiles (usec):
     |  1.00th=[  1270],  5.00th=[ 16319], 10.00th=[ 55837], 20.00th=[ 62129],
     | 30.00th=[ 66323], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[103285],
     | 99.00th=[137364], 99.50th=[143655], 99.90th=[158335], 99.95th=[162530],
     | 99.99th=[162530]
   bw (  KiB/s): min=14080, max=217088, per=7.09%, avg=29476.16, stdev=18011.56, samples=120
   iops        : min=  110, max= 1696, avg=230.27, stdev=140.72, samples=120
  lat (usec)   : 750=0.12%, 1000=0.40%
  lat (msec)   : 2=1.35%, 4=0.90%, 10=1.32%, 20=1.24%, 50=2.95%
  lat (msec)   : 100=86.22%, 250=5.52%
  cpu          : usr=0.13%, sys=0.01%, ctx=7119, majf=0, minf=47
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.0%, 16=49.9%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=0.0%, 16=4.2%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,13834,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1816: Sat Mar 27 15:35:26 2021
  write: IOPS=198, BW=24.8MiB/s (25.0MB/s)(1728MiB/69712msec); 0 zone resets
    slat (nsec): min=1352, max=1621.1k, avg=3257.27, stdev=15206.05
    clat (usec): min=680, max=163066, avg=69516.35, stdev=21413.78
     lat (usec): min=684, max=163068, avg=69519.61, stdev=21412.27
    clat percentiles (usec):
     |  1.00th=[   996],  5.00th=[ 15401], 10.00th=[ 55837], 20.00th=[ 62653],
     | 30.00th=[ 66847], 40.00th=[ 69731], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 87557], 95.00th=[102237],
     | 99.00th=[135267], 99.50th=[141558], 99.90th=[156238], 99.95th=[158335],
     | 99.99th=[162530]
   bw (  KiB/s): min=13056, max=212992, per=7.09%, avg=29448.45, stdev=17652.17, samples=120
   iops        : min=  102, max= 1664, avg=230.02, stdev=137.92, samples=120
  lat (usec)   : 750=0.12%, 1000=0.95%
  lat (msec)   : 2=0.72%, 4=0.49%, 10=1.69%, 20=1.35%, 50=2.91%
  lat (msec)   : 100=86.25%, 250=5.53%
  cpu          : usr=0.12%, sys=0.01%, ctx=7094, majf=0, minf=45
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.0%, 16=49.9%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=0.0%, 16=4.2%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,13823,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1817: Sat Mar 27 15:35:26 2021
  write: IOPS=202, BW=25.3MiB/s (26.5MB/s)(1762MiB/69711msec); 0 zone resets
    slat (nsec): min=641, max=371884, avg=3232.75, stdev=5717.76
    clat (usec): min=599, max=170235, avg=68127.43, stdev=23377.67
     lat (usec): min=611, max=170237, avg=68130.66, stdev=23376.35
    clat percentiles (usec):
     |  1.00th=[  1012],  5.00th=[  5800], 10.00th=[ 49546], 20.00th=[ 61604],
     | 30.00th=[ 66323], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[102237],
     | 99.00th=[135267], 99.50th=[143655], 99.90th=[160433], 99.95th=[170918],
     | 99.99th=[170918]
   bw (  KiB/s): min=13568, max=285440, per=7.23%, avg=30039.21, stdev=24035.80, samples=120
   iops        : min=  106, max= 2230, avg=234.67, stdev=187.78, samples=120
  lat (usec)   : 750=0.34%, 1000=0.62%
  lat (msec)   : 2=1.12%, 4=1.45%, 10=3.10%, 20=0.91%, 50=2.46%
  lat (msec)   : 100=84.57%, 250=5.42%
  cpu          : usr=0.14%, sys=0.00%, ctx=7212, majf=0, minf=46
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.0%, 16=49.9%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=4.0%, 16=0.1%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14099,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1818: Sat Mar 27 15:35:26 2021
  write: IOPS=207, BW=25.9MiB/s (27.2MB/s)(1806MiB/69711msec); 0 zone resets
    slat (nsec): min=1182, max=913405, avg=3604.40, stdev=12379.36
    clat (usec): min=292, max=166003, avg=66469.08, stdev=25174.43
     lat (usec): min=302, max=166006, avg=66472.69, stdev=25172.22
    clat percentiles (usec):
     |  1.00th=[   840],  5.00th=[  3523], 10.00th=[ 20579], 20.00th=[ 60031],
     | 30.00th=[ 65799], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 71828],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[101188],
     | 99.00th=[133694], 99.50th=[143655], 99.90th=[158335], 99.95th=[166724],
     | 99.99th=[166724]
   bw (  KiB/s): min=13056, max=375040, per=7.41%, avg=30785.82, stdev=32084.48, samples=120
   iops        : min=  102, max= 2930, avg=240.48, stdev=250.66, samples=120
  lat (usec)   : 500=0.06%, 750=0.62%, 1000=1.09%
  lat (msec)   : 2=1.68%, 4=2.06%, 10=2.75%, 20=1.65%, 50=2.39%
  lat (msec)   : 100=82.39%, 250=5.31%
  cpu          : usr=0.12%, sys=0.02%, ctx=7362, majf=0, minf=45
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.1%, 16=49.8%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=4.1%, 16=0.1%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14450,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1819: Sat Mar 27 15:35:26 2021
  write: IOPS=204, BW=25.6MiB/s (26.8MB/s)(1784MiB/69711msec); 0 zone resets
    slat (nsec): min=1202, max=1190.4k, avg=3417.17, stdev=14236.45
    clat (usec): min=652, max=169074, avg=67297.04, stdev=24237.76
     lat (usec): min=657, max=169077, avg=67300.46, stdev=24235.69
    clat percentiles (usec):
     |  1.00th=[  1221],  5.00th=[  4113], 10.00th=[ 42730], 20.00th=[ 60556],
     | 30.00th=[ 65799], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[102237],
     | 99.00th=[132645], 99.50th=[143655], 99.90th=[160433], 99.95th=[168821],
     | 99.99th=[168821]
   bw (  KiB/s): min=13312, max=327936, per=7.32%, avg=30406.99, stdev=27853.57, samples=120
   iops        : min=  104, max= 2562, avg=237.51, stdev=217.61, samples=120
  lat (usec)   : 750=0.06%, 1000=0.48%
  lat (msec)   : 2=2.61%, 4=1.76%, 10=2.34%, 20=1.37%, 50=2.59%
  lat (msec)   : 100=83.42%, 250=5.37%
  cpu          : usr=0.14%, sys=0.00%, ctx=7425, majf=0, minf=43
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.1%, 16=49.8%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=3.9%, 16=0.3%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14273,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1820: Sat Mar 27 15:35:26 2021
  write: IOPS=205, BW=25.6MiB/s (26.9MB/s)(1788MiB/69712msec); 0 zone resets
    slat (nsec): min=1032, max=828266, avg=3509.99, stdev=13388.19
    clat (usec): min=558, max=162352, avg=67172.07, stdev=24404.43
     lat (usec): min=568, max=162355, avg=67175.58, stdev=24402.32
    clat percentiles (usec):
     |  1.00th=[   938],  5.00th=[  3851], 10.00th=[ 40109], 20.00th=[ 60556],
     | 30.00th=[ 65799], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[102237],
     | 99.00th=[135267], 99.50th=[143655], 99.90th=[158335], 99.95th=[160433],
     | 99.99th=[162530]
   bw (  KiB/s): min=13312, max=336896, per=7.33%, avg=30475.25, stdev=28659.08, samples=120
   iops        : min=  104, max= 2632, avg=238.07, stdev=223.90, samples=120
  lat (usec)   : 750=0.32%, 1000=0.99%
  lat (msec)   : 2=2.45%, 4=1.37%, 10=2.31%, 20=1.17%, 50=2.78%
  lat (msec)   : 100=83.28%, 250=5.33%
  cpu          : usr=0.12%, sys=0.02%, ctx=7470, majf=0, minf=44
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.1%, 16=49.8%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=4.1%, 16=0.1%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14304,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1821: Sat Mar 27 15:35:26 2021
  write: IOPS=202, BW=25.3MiB/s (26.6MB/s)(1766MiB/69712msec); 0 zone resets
    slat (nsec): min=1302, max=753046, avg=3944.56, stdev=19073.22
    clat (usec): min=156, max=162511, avg=68007.69, stdev=23448.48
     lat (usec): min=422, max=162514, avg=68011.63, stdev=23445.15
    clat percentiles (usec):
     |  1.00th=[   807],  5.00th=[  5407], 10.00th=[ 49021], 20.00th=[ 61604],
     | 30.00th=[ 65799], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[102237],
     | 99.00th=[132645], 99.50th=[143655], 99.90th=[160433], 99.95th=[160433],
     | 99.99th=[162530]
   bw (  KiB/s): min=14080, max=291840, per=7.24%, avg=30098.50, stdev=24616.76, samples=120
   iops        : min=  110, max= 2280, avg=235.12, stdev=192.32, samples=120
  lat (usec)   : 250=0.01%, 500=0.13%, 750=0.71%, 1000=1.11%
  lat (msec)   : 2=1.18%, 4=0.94%, 10=2.22%, 20=1.33%, 50=2.48%
  lat (msec)   : 100=84.47%, 250=5.41%
  cpu          : usr=0.10%, sys=0.04%, ctx=7246, majf=0, minf=47
  IO depths    : 1=0.1%, 2=0.1%, 4=0.2%, 8=50.2%, 16=49.6%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=4.0%, 16=0.2%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14127,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1822: Sat Mar 27 15:35:26 2021
  write: IOPS=198, BW=24.9MiB/s (26.1MB/s)(1734MiB/69711msec); 0 zone resets
    slat (nsec): min=1243, max=888278, avg=3136.71, stdev=7996.51
    clat (usec): min=502, max=161370, avg=69257.08, stdev=21760.47
     lat (usec): min=636, max=161372, avg=69260.22, stdev=21759.32
    clat percentiles (usec):
     |  1.00th=[  1012],  5.00th=[ 12780], 10.00th=[ 55313], 20.00th=[ 62653],
     | 30.00th=[ 66323], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[102237],
     | 99.00th=[135267], 99.50th=[143655], 99.90th=[156238], 99.95th=[158335],
     | 99.99th=[160433]
   bw (  KiB/s): min=13568, max=225792, per=7.11%, avg=29551.98, stdev=18752.68, samples=120
   iops        : min=  106, max= 1764, avg=230.85, stdev=146.51, samples=120
  lat (usec)   : 750=0.18%, 1000=0.71%
  lat (msec)   : 2=0.72%, 4=0.80%, 10=2.11%, 20=1.32%, 50=2.69%
  lat (msec)   : 100=85.73%, 250=5.75%
  cpu          : usr=0.11%, sys=0.02%, ctx=7062, majf=0, minf=43
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.0%, 16=50.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=4.1%, 16=0.1%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,13871,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1823: Sat Mar 27 15:35:26 2021
  write: IOPS=213, BW=26.7MiB/s (28.0MB/s)(1863MiB/69712msec); 0 zone resets
    slat (nsec): min=1223, max=805253, avg=3589.06, stdev=10337.56
    clat (usec): min=356, max=162777, avg=64460.53, stdev=27269.27
     lat (usec): min=378, max=162779, avg=64464.12, stdev=27267.31
    clat percentiles (usec):
     |  1.00th=[   848],  5.00th=[  1516], 10.00th=[  6128], 20.00th=[ 58459],
     | 30.00th=[ 64750], 40.00th=[ 67634], 50.00th=[ 70779], 60.00th=[ 71828],
     | 70.00th=[ 73925], 80.00th=[ 76022], 90.00th=[ 85459], 95.00th=[101188],
     | 99.00th=[135267], 99.50th=[143655], 99.90th=[158335], 99.95th=[158335],
     | 99.99th=[162530]
   bw (  KiB/s): min=12800, max=490496, per=7.64%, avg=31763.64, stdev=42532.19, samples=120
   iops        : min=  100, max= 3832, avg=248.14, stdev=332.29, samples=120
  lat (usec)   : 500=0.03%, 750=0.44%, 1000=1.77%
  lat (msec)   : 2=3.60%, 4=2.04%, 10=3.93%, 20=0.94%, 50=2.22%
  lat (msec)   : 100=79.90%, 250=5.14%
  cpu          : usr=0.14%, sys=0.01%, ctx=7667, majf=0, minf=46
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.1%, 16=49.8%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=0.1%, 16=4.2%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14907,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1824: Sat Mar 27 15:35:26 2021
  write: IOPS=206, BW=25.9MiB/s (27.1MB/s)(1802MiB/69711msec); 0 zone resets
    slat (nsec): min=1232, max=506345, avg=3337.57, stdev=7748.09
    clat (usec): min=369, max=169609, avg=66620.47, stdev=25273.24
     lat (usec): min=421, max=169612, avg=66623.80, stdev=25271.62
    clat percentiles (usec):
     |  1.00th=[   889],  5.00th=[  1991], 10.00th=[ 25035], 20.00th=[ 60556],
     | 30.00th=[ 65799], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[103285],
     | 99.00th=[132645], 99.50th=[143655], 99.90th=[158335], 99.95th=[168821],
     | 99.99th=[168821]
   bw (  KiB/s): min=13312, max=367104, per=7.39%, avg=30717.55, stdev=31364.68, samples=120
   iops        : min=  104, max= 2868, avg=239.94, stdev=245.04, samples=120
  lat (usec)   : 500=0.02%, 750=0.44%, 1000=1.27%
  lat (msec)   : 2=3.28%, 4=1.48%, 10=2.01%, 20=1.28%, 50=2.22%
  lat (msec)   : 100=82.61%, 250=5.40%
  cpu          : usr=0.12%, sys=0.02%, ctx=7338, majf=0, minf=43
  IO depths    : 1=0.1%, 2=0.1%, 4=0.2%, 8=50.1%, 16=49.5%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.7%, 8=4.1%, 16=0.2%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14418,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1825: Sat Mar 27 15:35:26 2021
  write: IOPS=206, BW=25.8MiB/s (27.0MB/s)(1798MiB/69711msec); 0 zone resets
    slat (nsec): min=1031, max=2532.2k, avg=3633.47, stdev=23283.17
    clat (usec): min=528, max=167188, avg=66794.78, stdev=24812.95
     lat (usec): min=602, max=167190, avg=66798.42, stdev=24811.29
    clat percentiles (usec):
     |  1.00th=[  1004],  5.00th=[  4490], 10.00th=[ 28967], 20.00th=[ 60556],
     | 30.00th=[ 65799], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 71828],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[101188],
     | 99.00th=[135267], 99.50th=[141558], 99.90th=[160433], 99.95th=[160433],
     | 99.99th=[166724]
   bw (  KiB/s): min=13056, max=357376, per=7.37%, avg=30640.23, stdev=30497.32, samples=120
   iops        : min=  102, max= 2792, avg=239.36, stdev=238.26, samples=120
  lat (usec)   : 750=0.06%, 1000=0.90%
  lat (msec)   : 2=1.50%, 4=1.89%, 10=3.96%, 20=1.20%, 50=2.37%
  lat (msec)   : 100=82.82%, 250=5.30%
  cpu          : usr=0.12%, sys=0.03%, ctx=7421, majf=0, minf=43
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.1%, 16=49.9%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=3.9%, 16=0.2%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14381,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1826: Sat Mar 27 15:35:26 2021
  write: IOPS=222, BW=27.8MiB/s (29.1MB/s)(1752MiB/63032msec); 0 zone resets
    slat (nsec): min=1282, max=458756, avg=3077.00, stdev=5015.08
    clat (usec): min=361, max=169729, avg=68518.70, stdev=22905.36
     lat (usec): min=411, max=169733, avg=68521.78, stdev=22904.33
    clat percentiles (usec):
     |  1.00th=[   750],  5.00th=[  7242], 10.00th=[ 53216], 20.00th=[ 62129],
     | 30.00th=[ 66323], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[102237],
     | 99.00th=[135267], 99.50th=[143655], 99.90th=[164627], 99.95th=[168821],
     | 99.99th=[168821]
   bw (  KiB/s): min=12544, max=264704, per=7.19%, avg=29862.85, stdev=22214.27, samples=120
   iops        : min=   98, max= 2068, avg=233.29, stdev=173.55, samples=120
  lat (usec)   : 500=0.01%, 750=1.02%, 1000=1.83%
  lat (msec)   : 2=0.83%, 4=0.60%, 10=1.28%, 20=1.04%, 50=2.74%
  lat (msec)   : 100=85.25%, 250=5.39%
  cpu          : usr=0.14%, sys=0.01%, ctx=7059, majf=0, minf=43
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.0%, 16=49.9%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=0.1%, 16=4.1%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14016,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1827: Sat Mar 27 15:35:26 2021
  write: IOPS=196, BW=24.6MiB/s (25.8MB/s)(1714MiB/69711msec); 0 zone resets
    slat (nsec): min=1172, max=832995, avg=3376.31, stdev=12929.95
    clat (usec): min=304, max=200601, avg=70080.47, stdev=21141.89
     lat (usec): min=312, max=200604, avg=70083.85, stdev=21139.68
    clat percentiles (usec):
     |  1.00th=[  1401],  5.00th=[ 25297], 10.00th=[ 56361], 20.00th=[ 62653],
     | 30.00th=[ 66847], 40.00th=[ 69731], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 87557], 95.00th=[103285],
     | 99.00th=[137364], 99.50th=[145753], 99.90th=[185598], 99.95th=[196084],
     | 99.99th=[200279]
   bw (  KiB/s): min=14336, max=189440, per=7.03%, avg=29211.35, stdev=15583.29, samples=120
   iops        : min=  112, max= 1480, avg=228.15, stdev=121.75, samples=120
  lat (usec)   : 500=0.01%, 750=0.01%, 1000=0.31%
  lat (msec)   : 2=1.22%, 4=0.74%, 10=1.14%, 20=0.98%, 50=3.13%
  lat (msec)   : 100=86.87%, 250=5.59%
  cpu          : usr=0.13%, sys=0.00%, ctx=7019, majf=0, minf=43
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.1%, 16=49.8%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=4.0%, 16=0.1%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,13713,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1828: Sat Mar 27 15:35:26 2021
  write: IOPS=202, BW=25.4MiB/s (26.6MB/s)(1769MiB/69712msec); 0 zone resets
    slat (nsec): min=1182, max=366163, avg=3341.27, stdev=7487.65
    clat (usec): min=715, max=164634, avg=67907.99, stdev=23644.95
     lat (usec): min=721, max=164636, avg=67911.33, stdev=23643.20
    clat percentiles (usec):
     |  1.00th=[  1123],  5.00th=[  5211], 10.00th=[ 47449], 20.00th=[ 61604],
     | 30.00th=[ 65799], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[102237],
     | 99.00th=[135267], 99.50th=[143655], 99.90th=[158335], 99.95th=[158335],
     | 99.99th=[164627]
   bw (  KiB/s): min=14080, max=297728, per=7.26%, avg=30149.72, stdev=25139.03, samples=120
   iops        : min=  110, max= 2326, avg=235.53, stdev=196.40, samples=120
  lat (usec)   : 750=0.01%, 1000=0.69%
  lat (msec)   : 2=1.15%, 4=2.10%, 10=2.81%, 20=1.14%, 50=2.42%
  lat (msec)   : 100=84.15%, 250=5.53%
  cpu          : usr=0.11%, sys=0.03%, ctx=7211, majf=0, minf=43
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.1%, 16=49.8%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=4.1%, 16=0.1%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14151,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1829: Sat Mar 27 15:35:26 2021
  write: IOPS=204, BW=25.6MiB/s (26.8MB/s)(1782MiB/69712msec); 0 zone resets
    slat (nsec): min=1223, max=2354.8k, avg=3825.32, stdev=24810.79
    clat (usec): min=528, max=163093, avg=67393.90, stdev=24108.21
     lat (usec): min=622, max=163095, avg=67397.73, stdev=24105.02
    clat percentiles (usec):
     |  1.00th=[  1012],  5.00th=[  4883], 10.00th=[ 43254], 20.00th=[ 61080],
     | 30.00th=[ 65799], 40.00th=[ 68682], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 86508], 95.00th=[102237],
     | 99.00th=[132645], 99.50th=[143655], 99.90th=[156238], 99.95th=[160433],
     | 99.99th=[162530]
   bw (  KiB/s): min=13312, max=323584, per=7.31%, avg=30368.14, stdev=27455.12, samples=120
   iops        : min=  104, max= 2528, avg=237.17, stdev=214.51, samples=120
  lat (usec)   : 750=0.13%, 1000=0.83%
  lat (msec)   : 2=1.40%, 4=1.79%, 10=3.13%, 20=1.36%, 50=2.43%
  lat (msec)   : 100=83.52%, 250=5.40%
  cpu          : usr=0.12%, sys=0.02%, ctx=7331, majf=0, minf=44
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.2%, 16=49.7%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=4.0%, 16=0.1%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,14256,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16
random-write-parallel: (groupid=0, jobs=1): err= 0: pid=1830: Sat Mar 27 15:35:26 2021
  write: IOPS=196, BW=24.6MiB/s (25.8MB/s)(1712MiB/69712msec); 0 zone resets
    slat (nsec): min=1283, max=471500, avg=3065.88, stdev=5839.88
    clat (usec): min=568, max=162309, avg=70131.67, stdev=20840.50
     lat (usec): min=577, max=162312, avg=70134.73, stdev=20839.28
    clat percentiles (usec):
     |  1.00th=[  1237],  5.00th=[ 24773], 10.00th=[ 56886], 20.00th=[ 63177],
     | 30.00th=[ 66847], 40.00th=[ 69731], 50.00th=[ 70779], 60.00th=[ 72877],
     | 70.00th=[ 74974], 80.00th=[ 76022], 90.00th=[ 87557], 95.00th=[103285],
     | 99.00th=[135267], 99.50th=[143655], 99.90th=[158335], 99.95th=[160433],
     | 99.99th=[162530]
   bw (  KiB/s): min=13824, max=180992, per=7.02%, avg=29184.56, stdev=14861.24, samples=120
   iops        : min=  108, max= 1414, avg=227.98, stdev=116.10, samples=120
  lat (usec)   : 750=0.10%, 1000=0.64%
  lat (msec)   : 2=0.91%, 4=0.72%, 10=1.37%, 20=0.72%, 50=2.90%
  lat (msec)   : 100=86.93%, 250=5.72%
  cpu          : usr=0.12%, sys=0.01%, ctx=6954, majf=0, minf=43
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=50.0%, 16=49.9%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=95.8%, 8=4.0%, 16=0.1%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,13699,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=16

Run status group 0 (all jobs):
  WRITE: bw=406MiB/s (426MB/s), 24.6MiB/s-27.8MiB/s (25.8MB/s-29.1MB/s), io=27.6GiB (29.7GB), run=63032-69712msec
```
</details>

# Example Read Runs

```
fio --name=read --ioengine=posixaio --rw=read --bs=128k --numjobs=1 --size=4g --iodepth=1 --runtime=60 --time_based --end_fsync=1 --output=seq-read-report.txt
```

<details>
<summary>
DS9: 
READ: bw=5422MiB/s (5685MB/s), 5422MiB/s-5422MiB/s (5685MB/s-5685MB/s), io=318GiB (341GB), run=60001-60001msec
</summary>

```
read: (g=0): rw=read, bs=(R) 128KiB-128KiB, (W) 128KiB-128KiB, (T) 128KiB-128KiB, ioengine=posixaio, iodepth=1
fio-3.12
Starting 1 process
read: Laying out IO file (1 file / 4096MiB)

read: (groupid=0, jobs=1): err= 0: pid=5462: Sat Mar 27 15:48:51 2021
  read: IOPS=43.4k, BW=5422MiB/s (5685MB/s)(318GiB/60001msec)
    slat (nsec): min=230, max=103363, avg=776.49, stdev=118.38
    clat (usec): min=13, max=469, avg=22.05, stdev= 2.35
     lat (usec): min=14, max=470, avg=22.83, stdev= 2.39
    clat percentiles (nsec):
     |  1.00th=[18048],  5.00th=[19328], 10.00th=[19584], 20.00th=[20352],
     | 30.00th=[21120], 40.00th=[21888], 50.00th=[22144], 60.00th=[22400],
     | 70.00th=[22912], 80.00th=[23424], 90.00th=[24192], 95.00th=[24704],
     | 99.00th=[26496], 99.50th=[27776], 99.90th=[50432], 99.95th=[69120],
     | 99.99th=[72192]
   bw (  MiB/s): min= 5119, max= 6004, per=99.90%, avg=5416.46, stdev=297.44, samples=119
   iops        : min=40952, max=48032, avg=43331.61, stdev=2379.49, samples=119
  lat (usec)   : 20=14.85%, 50=85.05%, 100=0.10%, 250=0.01%, 500=0.01%
  cpu          : usr=4.99%, sys=6.04%, ctx=2602726, majf=0, minf=46
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=2602431,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
   READ: bw=5422MiB/s (5685MB/s), 5422MiB/s-5422MiB/s (5685MB/s-5685MB/s), io=318GiB (341GB), run=60001-60001msec
```

</details>
