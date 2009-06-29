type gt_param = {
    v0: float * float;   vid: float * float;   vjd: float * float;
    goal_dothit: int;   goal_boxhit: int;   goal_time: int;
    boxfudge: float
  }

type gt_report = {
    pvx: float array array;  pvy: float array array;
    vid': float * float;   vjd': float * float;
    badbox: int array array;   nbadbox: int;
    boxhit: int array array;   nboxhit: int;
    deadbox: int array array;  ndeadbox: int;
    deaddot: int array array;  ndeaddot: int;
    dothit: int array array;   ndothit: int;
    endtime: int
  }
    
external gridtrace : gt_param -> gt_report = "caml_gridtrace"
external testfun : int -> float array = "testfun"

