import oci
from borneo import (
    PutRequest, PutOption,  NoSQLHandle, NoSQLHandleConfig)
from borneo.iam import SignatureProvider
from fdk import response

import io
import json
import logging
import logging.handlers
import logging.config

def handler(ctx, data: io.BytesIO=None):
    func_name = ctx.FnName()
    global logger
    logger = logging.getLogger(func_name)
    logger.setLevel(logging.INFO)
    logger.info("Function started.")

    try:
        cfg = ctx.Config()
        endpoint = cfg["ENDPOINT"]
        compartment = cfg["COMPARTMENT"]
        table_name = cfg["NOSQL_TABLE_NAME"]
        function_endpoint = cfg["FUNCTION_ENDPOINT"]
        function_ocid = cfg["FUNCTION_OCID"]
    except Exception:
        logger.error("Missing function parameters.")
        raise
    try:
        body = json.loads(data.getvalue())
        event_id = body["eventID"]
        object_name = body["data"]["resourceName"]
        nosql_insert_first(event_id,object_name,endpoint,compartment,table_name)
        invoke_launch_vm_fn(event_id,object_name,function_endpoint,function_ocid)
    except (Exception) as ex:
        logger.error("Function error: " + ex)
        raise

    logger.info("Function complete.")
    return response.Response(
        ctx,
        response_data=json.dumps(body),
        headers={"Content-Type": "application/json"}
    )

def nosql_insert_first (event_id,object_name,endpoint,compartment,table_name):
   handle = None
   try:
       logger.info("Creating job for " + object_name + ".")

       # Silence NoSQL client debug logs
       urllib3_logger = logging.getLogger('urllib3')
       urllib3_logger.setLevel(logging.WARN)
       oci_logger = logging.getLogger('oci')
       oci_logger.setLevel(logging.WARN)

       signer = oci.auth.signers.get_resource_principals_signer()
       NoSQLprovider = SignatureProvider(provider=signer)
       NoSQLconfig = NoSQLHandleConfig(endpoint,NoSQLprovider).set_default_compartment(compartment).set_logger(logger)
       handle = NoSQLHandle(NoSQLconfig)
       request = PutRequest().set_table_name(table_name)
       status ='Object Uploaded'
       value = {'event_id': str(event_id), 'object_name': str(object_name), 'status': str(status)}
       request.set_value(value).set_option(PutOption.IF_ABSENT)
       handle.put(request)

   finally:
        if handle is not None:
            handle.close()

def invoke_launch_vm_fn (event_id,object_name,function_endpoint,function_ocid):
    logger.info("Deploying worker for " + object_name + ".")
    function_body = '{"event_id":"'+ event_id+'"}'
    signer = oci.auth.signers.get_resource_principals_signer()
    client = oci.functions.FunctionsInvokeClient(config={}, signer=signer, service_endpoint=function_endpoint)
    client.invoke_function(function_id=function_ocid, invoke_function_body=function_body)