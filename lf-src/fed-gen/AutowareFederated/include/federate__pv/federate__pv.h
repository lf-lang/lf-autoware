#ifndef _federate__pv_main_H
#define _federate__pv_main_H
#ifndef _FEDERATE__PV_MAIN_H // necessary for arduino-cli, which automatically includes headers that are not used
#ifndef TOP_LEVEL_PREAMBLE_182949133_H
#define TOP_LEVEL_PREAMBLE_182949133_H
/*Correspondence: Range: [(21, 0), (22, 20)) -> Range: [(0, 0), (1, 20)) (verbatim=true; src=/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/src/federate__pv.lf)*/#include "autoware/planning_validator/node.hpp"
#include "utils.hpp"
/*Correspondence: Range: [(25, 0), (38, 6)) -> Range: [(0, 0), (13, 6)) (verbatim=true; src=/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/src/federate__pv.lf)*/#ifdef __cplusplus
extern "C" {
#endif
#include "core/federated/federate.h"
#include "core/federated/network/net_common.h"
#include "core/federated/network/net_util.h"
#include "core/federated/network/socket_common.h"
#include "core/federated/clock-sync.h"
#include "core/threaded/reactor_threaded.h"
#include "core/utils/util.h"
extern federate_instance_t _fed;
#ifdef __cplusplus
}
#endif
#endif // TOP_LEVEL_PREAMBLE_182949133_H
#ifndef TOP_LEVEL_PREAMBLE_16196099_H
#define TOP_LEVEL_PREAMBLE_16196099_H
/*Correspondence: Range: [(5, 4), (6, 20)) -> Range: [(0, 0), (1, 20)) (verbatim=true; src=/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/planning_validator/planning_validator_main.lf)*/#include "autoware/planning_validator/node.hpp"
#include "utils.hpp"
#endif // TOP_LEVEL_PREAMBLE_16196099_H
#ifdef __cplusplus
extern "C" {
#endif
#include "../include/api/schedule.h"
#include "../include/core/reactor.h"
#ifdef __cplusplus
}
#endif
typedef struct federate__pv_self_t{
    self_base_t base; // This field is only to be used by the runtime, not the user.
    int end[0]; // placeholder; MSVC does not compile empty structs
} federate__pv_self_t;
#endif
#endif
