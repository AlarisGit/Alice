import json
import requests
from random import randint

def get_response(rq_data):
    print("=====> PY: in get_response")
    status_code = 0
    if isinstance(rq_data, str):
        try:
            print("=====> PY: load json")
            rq_data = json.loads(rq_data)
        except Exception as ex:
            response = "400: invalid request %s" % str(ex)
        else:
            print("=====> PY: do URL")
            response = requests.post('https://alice.alarislabs.com/api/v1/license', headers={'Content-Type': 'application/json'}, json=rq_data)
            status_code = response.status_code
            print("=====> PY: got HTTP response with status %d" % status_code)
            if status_code == 200:
                response = response.content
            else:
                response = str(response.reason)
    else:
        response = "400: invalid request data - not a json string"

    print("=====> PY: return response %s" % str((status_code, response)))
    return (status_code, response)

