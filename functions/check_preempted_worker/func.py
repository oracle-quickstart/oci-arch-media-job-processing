## If that preemtible worker already completed its work, this function will just exit without doing any work.
## If the preemtible worker had failed in any other phase of processing the object, it will re-process by invoking launch_vm function
# This function is called when there is an preemtible action event (when the preemtible instance is terminated by OCI)

import oci
from borneo import (
    QueryRequest, NoSQLHandle, NoSQLHandleConfig, PrepareRequest)
from borneo.iam import SignatureProvider
from fdk import response

import io
import json
import logging
import logging.handlers
import logging.config

def handler(ctx, data: io.BytesIO=None):
    global func_name
    func_name = ctx.FnName()
    global logger
    logger = logging.getLogger(func_name)
    logger.setLevel(logging.INFO)
    logger.info("Function started.")

    try:
        cfg = ctx.Config()
        global endpoint
        endpoint = cfg["ENDPOINT"]
        global compartment
        compartment = cfg["COMPARTMENT"]
        global table_name
        table_name = cfg["NOSQL_TABLE_NAME"]
        global function_endpoint
        function_endpoint = cfg["FUNCTION_ENDPOINT"]
        global function_ocid
        function_ocid = cfg["FUNCTION_OCID"]
    except Exception:
        logger.error("Missing function parameters.")
        raise
    try:
        body = json.loads(data.getvalue())
        preempted_instance_id = body["data"]["resourceId"]
        check_job_status (preempted_instance_id)
    except (Exception) as ex:
        logger.error("Function error: " + ex)
        raise

    logger.info("Function complete.")
    return response.Response(
        ctx,
        response_data=json.dumps(body),
        headers={"Content-Type": "application/json"}
    )

def check_job_status (preempted_instance_id):
   handle = None
   try:
       logger.info("Checking job status of preemptable worker " + preempted_instance_id + ".")

       # Silence NoSQL client debug logs
       urllib3_logger = logging.getLogger('urllib3')
       urllib3_logger.setLevel(logging.WARN)
       oci_logger = logging.getLogger('oci')
       oci_logger.setLevel(logging.WARN)

       signer = oci.auth.signers.get_resource_principals_signer()
       NoSQLprovider = SignatureProvider(provider=signer)
       NoSQLconfig = NoSQLHandleConfig(endpoint,NoSQLprovider).set_default_compartment(compartment).set_logger(logger)
       handle = NoSQLHandle(NoSQLconfig)
       statement = 'select event_id,status from ' + table_name + ' where instance_id = "'+ preempted_instance_id +'"' 
       request = PrepareRequest().set_statement(statement)
       prepared_result = handle.prepare(request)
       request = QueryRequest().set_prepared_statement(prepared_result)
       while True:
            result = handle.query(request)
            for r in result.get_results():
                s = json.dumps(r)
                data = json.loads(s)
                current_status = data['status']
                event_id = data['event_id']
                object_name = data['object_name']
                if current_status == 'Done':
                    logger.info("Job completed sucessfully.")
                    exit()
                else:
                    logger.warn("Job was preempted.")
                    invoke_launch_vm_fn(event_id,object_name)
            if request.is_done():
                break
   finally:
        # If the handle isn't closed Python will not exit properly
        if handle is not None:
            handle.close()
            
def invoke_launch_vm_fn (event_id,object_name):
    logger.info("Redeploying worker for " + object_name + ".")
    function_body = '{"event_id":"'+ event_id+'"}'
    signer = oci.auth.signers.get_resource_principals_signer()
    client = oci.functions.FunctionsInvokeClient(config={}, signer=signer, service_endpoint=function_endpoint)
    client.invoke_function(function_id=function_ocid, invoke_function_body=function_body)