
CALL audit.log_load(
    'Gold',
    'dim_customers',
    CURRENT_TIMESTAMP::TIMESTAMP,
    CURRENT_TIMESTAMP::TIMESTAMP,
    18484,
    'SUCCESS'
);


SELECT *
FROM audit.load_log