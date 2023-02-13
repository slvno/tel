import sys

import requests
import fileinput

std_input_string = ""
for fileinput_line in fileinput.input():
    std_input_string += fileinput_line.rstrip()

std_input_string = std_input_string.rstrip()

try:
    res = requests.get(std_input_string)
    print(f"[{res.status_code}][{res.content}]")

except  Exception as e:
    print(f"Exception: [{str(e)}]")
    sys.exit(1)
finally:
    sys.exit(0)

# res.url
# print var
# https://httpbin.org/get
# res.history[0].url
# https://httpbin.org/status/301