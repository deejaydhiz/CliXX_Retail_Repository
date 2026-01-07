#!/bin/bash

echo ECS_CLUSTER=${aws_ecs_cluster.clixx_ecs_cluster.name} >> /etc/ecs/ecs.config

#Variables
DB_HOST=${aws_db_instance.clixx_rds_instance.address}
DB_PASS="W3lcome123"
LB_DNS=${aws_lb.clixx_nlb.dns_name}


mysql -u wordpressuser -p"${DB_PASS}" -h ${DB_HOST} -D wordpressdb <<EOF
    UPDATE wp_options SET option_value = "${LB_DNS}" WHERE option_value LIKE '%NLB%';
EOF