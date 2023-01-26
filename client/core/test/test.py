# from layer import get_value_py
# print("0x%08X" % get_value_py(0x02))

from libalice import get_license
rq_data = '{"key1": "value1", "key3": "value3"}'
response = get_license(rq_data)
print("=====> response", response)
