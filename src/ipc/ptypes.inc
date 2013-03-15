{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2001 by Free Pascal development team

    This file implements all the base types and limits required
    for a minimal POSIX compliant subset required to port the compiler
    to a new OS.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{***********************************************************************}
{                       POSIX TYPE DEFINITIONS                          }
{***********************************************************************}

{ Introduced defines
    - fs32bit, should be on if libc only supports sizeof(off_t)=4
               we assume one typically compiles C applications with 
               #define _FILE_OFFSET_BITS 64

All three tested systems (PPC,Alpha,2x i386) gave the same POSIX limits,
and all three 32-bit systems returned completely identical types too
(everything 32-bit except dev_t, which is assumed to be a result of devfs
introduction)
}

{$I ctypes.inc}
{$packrecords c}

Type

    dev_t    = cuint64;         { used for device numbers      }
    TDev     = dev_t;
    pDev     = ^dev_t;

    kDev_t   = cushort;         // Linux has two different device conventions
    TkDev    = KDev_t;          // kernel and glibc. This is kernel.
    pkDev    = ^kdev_t;

    ino_t    = clong;           { used for file serial numbers }
    TIno     = ino_t;
    pIno     = ^ino_t;

    ino64_t  = cuint64;
    TIno64   = ino64_t;
    pIno64   = ^ino64_t;

{$ifdef cpu64}
    mode_t   = cint;         { used for file attributes     }
{$else cpu64}
    mode_t   = cuint32;      { used for file attributes     }
{$endif cpu64}
    TMode    = mode_t;
    pMode    = ^mode_t;

    nlink_t  = cuint32;         { used for link counts         }
    TnLink   = nlink_t;
    pnLink   = ^nlink_t;

{$if not defined(fs32bit)}
    off_t    = cint64;          { used for file sizes          }
{$else}
    off_t    = cint;
{$endif}
    TOff     = off_t;
    pOff     = ^off_t;

    pid_t    = cint;          { used as process identifier   }
    TPid     = pid_t;
    pPid     = ^pid_t;

{$ifdef cpu64}
    size_t   = cuint64;         { as definied in the C standard}
    ssize_t  = cint64;          { used by function for returning number of bytes }
    clock_t  = cuint64;
    time_t   = cint64;           { used for returning the time  }
{$else}
    size_t   = cuint32;         { as definied in the C standard}
    ssize_t  = cint32;          { used by function for returning number of bytes }
    clock_t  = culong;
    time_t   = clong;           { used for returning the time  }
{$endif}
    wint_t    = cint32;
    TSize     = size_t;
    pSize     = ^size_t;
    psize_t   = pSize;
    TSSize    = ssize_t;
    pSSize    = ^ssize_t;
    TClock    = clock_t;
    pClock    = ^clock_t;
    TTime     = time_t;
    pTime     = ^time_t;
    ptime_t   = ^time_t;

    wchar_t   = cint32;
    pwchar_t  = ^wchar_t;

{$ifdef cpu64}
    uid_t    = cuint32;         { used for user ID type        }
    gid_t    = cuint32;         { used for group IDs           }
    ipc_pid_t = cint;
{$else cpu64}
    uid_t    = cuint32;         { used for user ID type        }
    gid_t    = cuint32;         { used for group IDs           }
    ipc_pid_t = cushort;      // still 16-bit
    ipc_gid_t = cushort;      // still 16-bit
{$endif cpu64}
    TUid     = uid_t;
    pUid     = ^uid_t;
    TGid     = gid_t;
    pGid     = ^gid_t;
    
    TIOCtlRequest = cInt;


    socklen_t= cuint32;
    TSockLen = socklen_t;
    pSockLen = ^socklen_t;

  timeval     = packed record
                 tv_sec:time_t;
                 tv_usec:clong;
                end;
  ptimeval    = ^timeval;
  TTimeVal    = timeval;

  timespec    = packed record
                 tv_sec   : time_t;
                 tv_nsec  : clong;
                end;
  ptimespec   = ^timespec;
  TTimeSpec   = timespec;

  {$ifdef cpu64}
  TStatfs = packed record
    fstype,            { File system type }
    bsize   : clong;    { Optimal block trensfer size }
    blocks,            { Data blocks in system }
    bfree,             { free blocks in system }
    bavail,            { Available free blocks to non-root users }
    files,             { File nodes in system }
    ffree   : culong;             { Free file nodes in system }
    fsid    : array[0..1] of cint;          { File system ID }
    namelen : clong; { Maximum name length in system }
    frsize  : clong;
    spare   : array [0..4] of clong; { For later use }
  end;
  {$else}
  TStatfs = packed record
    fstype,            { File system type }
    bsize   : cint;    { Optimal block trensfer size }
    blocks,            { Data blocks in system }
    bfree,             { free blocks in system }
    bavail,            { Available free blocks to non-root users }
    files,             { File nodes in system }
    ffree   : culong;  { Free file nodes in system }
    fsid    : array[0..1] of cint;          { File system ID }
    namelen,           { Maximum name length in system }
    frsize  : cint;
    spare   : array [0..4] of cint; { For later use }
  end;
  {$endif}
  PStatFS=^TStatFS;

  mbstate_value_t = record
    case byte of
      0: (__wch: wint_t);
      1: (__wchb: array[0..3] of char);
  end;
  
  mbstate_t = record
    __count: cint;
    __value: mbstate_value_t;
  end;
  pmbstate_t = ^mbstate_t;

  pthread_t = culong;

  sched_param = record
    __sched_priority: cint;
  end;

  pthread_attr_t = record
    __detachstate: cint;
    __schedpolicy: cint;
    __schedparam: sched_param;
    __inheritsched: cint;
    __scope: cint;
    __guardsize: size_t;
    __stackaddr_set: cint;
    __stackaddr: pointer;
    __stacksize: size_t;
  end;

  _pthread_fastlock = record
    __status: clong;
    __spinlock: cint;
  end;

  pthread_mutex_t = record
    __m_reserved: cint;
    __m_count: cint;
    __m_owner: pointer;
    __m_kind:  cint;
    __m_lock: _pthread_fastlock;
  end;

  pthread_mutexattr_t = record
    __mutexkind: cint;
  end;

  pthread_cond_t = record
    __c_lock: _pthread_fastlock;
    __c_waiting: pointer;
    __padding: array[0..48-1-sizeof(_pthread_fastlock)-sizeof(pointer)-sizeof(clonglong)] of byte;
    __align: clonglong;
  end;

  pthread_condattr_t = record
    __dummy: cint;
  end;

  pthread_key_t = cuint;

  pthread_rwlock_t = record
    __rw_readers: cint;
    __rw_writer: pointer;
    __rw_read_waiting: pointer;
    __rw_write_waiting: pointer;
    __rw_kind: cint;
    __rw_pshared: cint;
  end;

  pthread_rwlockattr_t = record
    __lockkind: cint;
    __pshared: cint;
  end;

  sem_t = record
     __sem_lock: _pthread_fastlock;
     __sem_value: cint;
     __sem_waiting: pointer;
  end;



CONST
    _PTHREAD_MUTEX_TIMED_NP      = 0;
    _PTHREAD_MUTEX_RECURSIVE_NP  = 1;
    _PTHREAD_MUTEX_ERRORCHECK_NP = 2;
    _PTHREAD_MUTEX_ADAPTIVE_NP   = 3;

    _PTHREAD_MUTEX_NORMAL     = _PTHREAD_MUTEX_TIMED_NP;
    _PTHREAD_MUTEX_RECURSIVE  = _PTHREAD_MUTEX_RECURSIVE_NP;
    _PTHREAD_MUTEX_ERRORCHECK = _PTHREAD_MUTEX_ERRORCHECK_NP;
    _PTHREAD_MUTEX_DEFAULT    = _PTHREAD_MUTEX_NORMAL;
    _PTHREAD_MUTEX_FAST_NP    = _PTHREAD_MUTEX_ADAPTIVE_NP;


   { System limits, POSIX value in parentheses, used for buffer and stack allocation }
   { took idefix' values}

    ARG_MAX        = 131072;   {4096}  { Maximum number of argument size     }
    NAME_MAX       = 255;      {14}    { Maximum number of bytes in filename }
    PATH_MAX       = 4095;     {255}   { Maximum number of bytes in pathname }
    SYS_NMLN       = 65;
{$ifdef FPC_USE_LIBC}
   SIG_MAXSIG      = 1024;      // highest signal version
{$else}
   SIG_MAXSIG      = 128;       // highest signal version
{$endif}

 { For getting/setting priority }
  Prio_Process = 0;
  Prio_PGrp    = 1;
  Prio_User    = 2;


