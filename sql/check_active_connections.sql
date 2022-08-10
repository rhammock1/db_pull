SELECT pid
FROM pg_stat_activity
WHERE datname = ANY('{node_env_1,node_ice}')
  AND (state = 'active' OR state = 'idle');
