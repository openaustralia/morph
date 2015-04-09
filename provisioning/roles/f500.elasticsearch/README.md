Elasticsearch
=============

Install and configure Elasticsearch.

Requirements
------------

None.

Role Variables
--------------

Select which version of Elasticsearch should be installed (`0.90`, `1.0` or `1.1`):

    elasticsearch_version: 1.1

Select the prefered state of the package (`present` or `latest`):

    elasticsearch_state: present

These configuration variables are used to create `/etc/elasticsearch/elasticsearch.yml`:

    elasticsearch_cluster_name: elasticsearch

    elasticsearch_node_name: ~
    elasticsearch_node_master: true
    elasticsearch_node_data: true
    elasticsearch_node_rack: ~
    elasticsearch_node_max_local_storage_nodes: ~

    elasticsearch_index_number_of_shards: 5
    elasticsearch_index_number_of_replicas: 1

    elasticsearch_path_conf: ~
    elasticsearch_path_data: ~
    elasticsearch_path_work: ~
    elasticsearch_path_logs: ~
    elasticsearch_path_plugins: ~

    elasticsearch_plugin_mandatory: ~

    elasticsearch_bootstrap_mlockall: false

    elasticsearch_network_bind_host: ~
    elasticsearch_network_publish_host: ~
    elasticsearch_network_host: "{{ ansible_eth0.ipv4.address }}"
    elasticsearch_transport_tcp_port: 9300
    elasticsearch_transport_tcp_compress: true
    elasticsearch_http_port: 9200
    elasticsearch_http_max_content_length: 100mb
    elasticsearch_http_enabled: true

    elasticsearch_gateway_type: local
    elasticsearch_gateway_recover_after_nodes: 1
    elasticsearch_gateway_recover_after_time: 5m
    elasticsearch_gateway_expected_nodes: 2

    elasticsearch_cluster_routing_allocation_node_initial_primaries_recoveries: ~
    elasticsearch_cluster_routing_allocation_node_concurrent_recoveries: ~
    elasticsearch_indices_recovery_max_bytes_per_sec: ~
    elasticsearch_indices_recovery_concurrent_streams: ~

    elasticsearch_discovery_zen_minimum_master_nodes: ~
    elasticsearch_discovery_zen_ping_timeout: ~
    elasticsearch_discovery_zen_ping_multicast_enabled: ~
    elasticsearch_discovery_zen_ping_unicast_hosts: ~

    elasticsearch_index_search_slowlog_threshold_query_warn: ~
    elasticsearch_index_search_slowlog_threshold_query_info: ~
    elasticsearch_index_search_slowlog_threshold_query_debug: ~
    elasticsearch_index_search_slowlog_threshold_query_trace: ~
    elasticsearch_index_search_slowlog_threshold_fetch_warn: ~
    elasticsearch_index_search_slowlog_threshold_fetch_info: ~
    elasticsearch_index_search_slowlog_threshold_fetch_debug: ~
    elasticsearch_index_search_slowlog_threshold_fetch_trace: ~
    elasticsearch_index_indexing_slowlog_threshold_index_warn: ~
    elasticsearch_index_indexing_slowlog_threshold_index_info: ~
    elasticsearch_index_indexing_slowlog_threshold_index_debug: ~
    elasticsearch_index_indexing_slowlog_threshold_index_trace: ~

    monitor_jvm_gc_young_warn: ~
    monitor_jvm_gc_young_info: ~
    monitor_jvm_gc_young_debug: ~
    monitor_jvm_gc_old_warn: ~
    monitor_jvm_gc_old_info: ~
    monitor_jvm_gc_old_debug: ~

This variable controls which template is used to create `/etc/elasticsearch/logging.yml`:

    elasticsearch_logging_template: logging.yml.j2

Dependencies
------------

Elasticsearch needs a Java Runtime Environment (JRE):

- geerlingguy.java

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: f500.elasticsearch, elasticsearch_cluster_name: "my elasticsearch cluster" }

License
-------

LGPLv3

Author Information
------------------

Jasper N. Brouwer, jasper@nerdsweide.nl

Ramon de la Fuente, ramon@delafuente.nl
