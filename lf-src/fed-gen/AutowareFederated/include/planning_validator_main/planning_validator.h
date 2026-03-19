#ifndef _planning_validator_H
#define _planning_validator_H
#ifndef _PLANNING_VALIDATOR_H // necessary for arduino-cli, which automatically includes headers that are not used
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
typedef struct planning_validator_self_t{
    self_base_t base; // This field is only to be used by the runtime, not the user.
    std::shared_ptr<autoware::planning_validator::PlanningValidatorNode> node;
    int end[0]; // placeholder; MSVC does not compile empty structs
} planning_validator_self_t;
#endif
#endif
