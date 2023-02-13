import os
import sys
import traceback
import urllib
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, HTTPServer
import re
import hashlib
import urllib.parse

"""
сервис должен прослушивать порт 
7777
 на локальном хосте (
127.0.0.1:7777);
"""
# hostName = "localhost"
hostName = "127.0.0.1"
serverPort = 7777


def select_int_chars(s):
    """Выбираем все цифры из строки"""
    return ''.join(filter(str.isdigit, s))


def get_response_validatePhoneNumber_string(path):
    path = path.strip()

    if len(path) == 0:
        return """{"status": false}"""

    r = re.compile(
        # +7 <code> ### ####
        # 8 <code> ### ####
        r'(^('
        r'((\+7|[8])[ ](982|986|912|934)[ ]\d{3}[ ]\d{4})|'
        # +7 <code> ### ## ##
        # 8 <code> ### ## ##
        r'((\+7|[8])[ ](982|986|912|934)[ ]\d{3}[ ]\d{2}[ ]\d{2})|'
        # +7 (<code>) ###-####
        # 8 (<code>) ###-####
        r'((\+7|[8])[ ](\(982\)|\(986\)|\(912\)|\(934\))[ ]\d{3}[-]\d{4})|'
        # +7<code>#######
        # 8<code>#######
        r'((\+7|[8])(982|986|912|934)\d{7})'
        r')$)'
    )
    results = r.findall(path)

    if not results:
        return """{"status": false}"""

    path = select_int_chars(path)

    code_code = path[1:4]

    first_plus = "+"
    code_contry = 7

    code_tel_1 = path[4:7]
    code_tel_2 = path[7:11]

    return '{\n  "normalized": "' + f"{first_plus}{code_contry}-{code_code}-{code_tel_1}-{code_tel_2}" \
           + '",\n  "status": true\n}'


class MyServer(BaseHTTPRequestHandler):

    # интерфейс GET /ping должен отвечает статус-кодом 200
    def ping(self):
        self.send_response(HTTPStatus.OK)
        self.end_headers()

    # , когда приложение готово обрабатывать запросы;
    # HTTP-интерфейс GET /shutdown должен немедленно завершать исполнение сервиса (статус-код в данном случае не важен).
    def shutdown_server(self):
        try:
            sys.exit(0)
        finally:
            print("Close")

    def validatePhoneNumber(self):

        try:
            parsed_url = urllib.parse.urlparse(self.path)

            get_qs = urllib.parse.parse_qs(parsed_url.query)

        except   BaseException as ex:
            # Get current system exception
            ex_type, ex_value, ex_traceback = sys.exc_info()

            # Extract unformatter stack traces as tuples
            trace_back = traceback.extract_tb(ex_traceback)

            # Format stacktrace
            stack_trace = list()

            for trace in trace_back:
                stack_trace.append("File : %s , Line : %d, Func.Name : %s, Message : %s" % (trace[0], trace[1],
                                                                                            trace[2], trace[3]))

            print("Exception type : %s " % ex_type.__name__)
            print("Exception message : %s" %ex_value)
            print("Stack trace : %s" %stack_trace)

            self.send_response(HTTPStatus.BAD_REQUEST)
            self.end_headers()

            return

        if not get_qs:
            self.send_response(HTTPStatus.BAD_REQUEST)
            self.end_headers()
            return

        key = 'phone_number'
        value = get_qs.get(key)

        if value is None:
            self.send_response(HTTPStatus.BAD_REQUEST)
            self.end_headers()
            return

        path = value[0]
        response_validatePhoneNumber_string = get_response_validatePhoneNumber_string(path)
        response_validatePhoneNumber_string_bytes = bytes(response_validatePhoneNumber_string, "utf-8")
        hash_object = hashlib.md5(response_validatePhoneNumber_string_bytes)
        ETag_str = hash_object.hexdigest()

        if self.headers.get("If-None-Match") and ETag_str == self.headers.get("If-None-Match"):
            self.send_response(HTTPStatus.NOT_MODIFIED, "Not Modified")
            self.send_header("Content-type", "application/json")
            self.send_header("Content-length", str(len(response_validatePhoneNumber_string_bytes)))
            self.send_header("Expires", self.headers.get("If-Modified-Since") or self.date_time_string() )
            self.send_header("Cache-Control", "no-cache, private, max-age=0, must-revalidate")
            self.send_header("Pragma", "no-cache")
            self.send_header("Last-Modified", self.headers.get("If-Modified-Since") or self.date_time_string())
            self.send_header("ETag", ETag_str)
            self.end_headers()
            return

        # If-None-Match: "ETag"
        # Сервер вернет, 304 Not Modified если значение заголовка ETag, которое он определяет для запрошенного ресурса,
        # совпадает со If-None-Match значением в запросе.

        self.send_response(HTTPStatus.OK)
        self.send_header("Content-type", "application/json")
        self.send_header("Content-length", str(len(response_validatePhoneNumber_string_bytes)))
        self.send_header("Expires", self.date_time_string())
        self.send_header("Cache-Control", "no-cache, private, max-age=0, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Last-Modified", self.date_time_string())
        self.send_header("ETag", ETag_str)
        self.end_headers()

        self.wfile.write(response_validatePhoneNumber_string_bytes)
        self.wfile.flush()

    directory = os.path.curdir

    def do_GET(self):
        parsed_url = urllib.parse.urlparse(self.path)

        if parsed_url.path == '/shutdown':
            self.shutdown_server()
        elif parsed_url.path == '/ping':
            self.ping()
        elif parsed_url.path == '/validatePhoneNumber':
            self.validatePhoneNumber()
        else:
            self.send_response(HTTPStatus.NOT_FOUND)
            self.end_headers()
            return


if __name__ == "__main__":
    print("Open")
    webServer = HTTPServer((hostName, serverPort), MyServer)

    try:
        webServer.serve_forever()
    except  Exception:
        webServer.shutdown()

    webServer.server_close()
    print("Close")

