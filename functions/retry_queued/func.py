import oci
from borneo import (
    QueryRequest, NoSQLHandle, NoSQLHandleConfig, PrepareRequest)
from borneo.iam import SignatureProvider

from fdk import response
from urllib.parse import urlparse, parse_qs

import io
import json
import logging
import logging.handlers
import logging.config

def instance_status(instance_id):
    compute_signer = oci.auth.signers.get_resource_principals_signer()
    compute_client = oci.core.ComputeClient(config={}, signer=compute_signer)

    try:
        instance_status = compute_client.get_instance(instance_id).data.lifecycle_state
    except:
        instance_status = 'not_found'

    return instance_status
    
def process_queued_files():
   handle = None
   queued_jobs = 0
   try:
       logger.info("Looking for queued jobs.")
 
        # Silence NoSQL client debug logs
       urllib3_logger = logging.getLogger('urllib3')
       urllib3_logger.setLevel(logging.WARN)
       oci_logger = logging.getLogger('oci')
       oci_logger.setLevel(logging.WARN)

       signer = oci.auth.signers.get_resource_principals_signer()
       NoSQLprovider = SignatureProvider(provider=signer)
       NoSQLconfig = NoSQLHandleConfig(endpoint,NoSQLprovider).set_default_compartment(compartment).set_logger(logger)
       handle = NoSQLHandle(NoSQLconfig)
       statement = 'select event_id,object_name,status,instance_id from ' + table_name 
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
                instance_id = data['instance_id']
                current_instance_status = instance_status(instance_id)
                
                # Queued job is caused by:
                # 1. A problem with on-demand provisioning. E.g. Compute limit reached.
                # 2. A prematurley termianted worker.
                
                if (((current_status != 'Done') and (current_instance_status == 'not_found')) 
                    or (((current_status != 'Done') and ('Error' not in current_status)) and (current_instance_status == 'TERMINATED'))) :
                    logger.warn("Queued job found for " + object_name + ".")
                    invoke_launch_vm_fn(event_id)
                    queued_jobs += 1
                else:
                   continue
            if request.is_done():
                logger.info("All jobs validated.")
                break
   finally:
        # If the handle isn't closed Python will not exit properly
        if handle is not None:
            handle.close()
        return queued_jobs
            
def invoke_launch_vm_fn(event_id):
    logger.info("Deploying worker.")
    function_body = '{"event_id":"'+ event_id+'"}'
    signer = oci.auth.signers.get_resource_principals_signer()
    client = oci.functions.FunctionsInvokeClient(config={}, signer=signer, service_endpoint=function_endpoint)
    resp = client.invoke_function(function_id=function_ocid, invoke_function_body=function_body)

def handler(ctx, data: io.BytesIO=None):
    global func_name
    func_name = ctx.FnName()
    global logger
    logger = logging.getLogger(func_name)
    logger.setLevel(logging.INFO)
    logger.info("Function started.")

    resp = {}
    
    # retrieving the request URL, e.g. "/v1/http-info"
    requesturl = ctx.RequestURL()
    logger.info("Request URL: " + json.dumps(requesturl))
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
        resp["Queued"] = process_queued_files()

    except (Exception) as ex:
        logger.error("Function error: " + ex)
        raise

    logger.info("Function complete.")

    return response.Response(
        ctx, 
        response_data=json.dumps(resp),
        headers={"Content-Type": "application/json"}
    )
    




    

    

    
   