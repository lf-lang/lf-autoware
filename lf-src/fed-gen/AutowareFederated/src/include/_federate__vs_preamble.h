#include "core/federated/federate.h"
#include "core/federated/network/net_common.h"
#include "core/federated/network/net_util.h"
#include "core/federated/network/socket_common.h"
#include "core/federated/clock-sync.h"
#include "core/threaded/reactor_threaded.h"
#include "core/utils/util.h"
extern federate_instance_t _fed;
interval_t _lf_action_delay_table[1];
lf_action_base_t* _lf_action_table[1];
size_t _lf_action_table_size = 1;
lf_action_base_t* _lf_zero_delay_cycle_action_table[0];
size_t _lf_zero_delay_cycle_action_table_size = 0;
reaction_t* network_input_reactions[1];
size_t num_network_input_reactions = 1;
reaction_t* port_absent_reaction[0];  // initialize to null pointers; see C99 6.7.8.10
size_t num_port_absent_reactions = 0;
#ifdef FEDERATED_DECENTRALIZED
    staa_t* staa_lst[1];
    size_t staa_lst_size = 1;

#endif // FEDERATED_DECENTRALIZED
void _lf_executable_preamble(environment_t* env) {
    
    // ***** Start initializing the federated execution. */
    // Initialize the socket mutexes
    lf_mutex_init(&lf_outbound_socket_mutex);
    init_shutdown_mutex();
    lf_cond_init(&lf_port_status_changed, &env->mutex);
    _lf_my_fed_id = 32;
    _fed.number_of_inbound_p2p_connections = 1;
    _fed.number_of_outbound_p2p_connections = 0;
    // Initialize the array of socket for incoming connections to -1.
    for (int i = 0; i < NUMBER_OF_FEDERATES; i++) {
        _fed.sockets_for_inbound_p2p_connections[i] = -1;
    }
    // Initialize the array of socket for outgoing connections to -1.
    for (int i = 0; i < NUMBER_OF_FEDERATES; i++) {
        _fed.sockets_for_outbound_p2p_connections[i] = -1;
    }
    // Connect to the RTI. This sets _fed.socket_TCP_RTI and _lf_rti_socket_UDP.
    lf_connect_to_rti("localhost", 0);
    // Create a socket server to listen to other federates.
    // If a port is specified by the user, that will be used
    // as the only possibility for the server. If not, the port
    // will be selected by the OS (by specifying port 0).
    lf_create_server(0);
    // Connect to remote federates for each physical connection or decentralized connection.
    // This is done in a separate thread because this thread will call
    // lf_connect_to_federate for each outbound connection at the same
    // time that the new thread is listening for such connections for inbound
    // connections. The thread will live until all connections have been established.
    lf_thread_create(&_fed.inbound_p2p_handling_thread_id, lf_handle_p2p_connections_from_federates, env);
}
void staa_initialization() {
    #ifdef FEDERATED_DECENTRALIZED
    staa_lst[0] = (staa_t*) malloc(sizeof(staa_t));
    staa_lst[0]->STAA = 0;
    staa_lst[0]->num_actions = 1;
    staa_lst[0]->actions = (lf_action_base_t**) malloc(sizeof(lf_action_base_t*) * 1);
    staa_lst[0]->actions[0] = _lf_action_table[0];
    
    #endif // FEDERATED_DECENTRALIZED
}
#define initialize_triggers_for_federate() \
do { \
    _lf_action_delay_table[0] = NEVER; \
    _lf_action_table[0] = (lf_action_base_t*)&federate__vs_nr_federate__vs_self[0]->_lf_networkMessage; \
    federate__vs_nr_federate__vs_self[0]->_lf_networkMessage.source_id = 31; \
    staa_initialization(); \
} \
while (0)
/**
* Generated function that sends information about connections between this federate and
* other federates where messages are routed through the RTI. Currently, this
* only includes logical connections when the coordination is centralized. This
* information is needed for the RTI to perform the centralized coordination.
* @see MSG_TYPE_NEIGHBOR_STRUCTURE in net_common.h
*/
void lf_send_neighbor_structure_to_RTI(int rti_socket) {
    interval_t candidate_tmp;
    size_t buffer_size = 1 + 8 + 
                    0 * ( sizeof(uint16_t) + sizeof(int64_t) ) +
                    0 * sizeof(uint16_t);
    unsigned char buffer_to_send[buffer_size];
    
    size_t message_head = 0;
    buffer_to_send[message_head] = MSG_TYPE_NEIGHBOR_STRUCTURE;
    message_head++;
    encode_int32((int32_t)0, &(buffer_to_send[message_head]));
    message_head+=sizeof(int32_t);
    encode_int32((int32_t)0, &(buffer_to_send[message_head]));
    message_head+=sizeof(int32_t);
    write_to_socket_fail_on_error(
        &rti_socket, 
        buffer_size,
        buffer_to_send,
        NULL,
        "Failed to send the neighbor structure message to the RTI."
    );
}
