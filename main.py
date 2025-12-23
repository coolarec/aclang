import subprocess
from flask import Flask, request, jsonify
import json
from flask_cors import CORS
import sys


def is_windows():
    return sys.platform.startswith("win")


app = Flask(__name__)
CORS(app)


@app.route("/check", methods=["POST"])
def syntaxAnalysis():
    source_code = request.json["code"]

    result = subprocess.run(
        ["./output/exe/Lexical"+(".exe" if is_windows() else "")],
        input=source_code,
        text=True,
        encoding="utf-8",
        capture_output=True
    )

    print(result.stdout)
    data = json.loads(result.stdout)
    return jsonify({
        "success": True,
        "code": len(source_code),
        "data": data
    })


@app.route("/symbol_table", methods=["POST"])
def get_symbol_table():
    try:
        source_code = request.json["code"]

        result = subprocess.run(
            ["./output/exe/symbol_table"+(".exe" if is_windows() else "")],
            input=source_code,
            text=True,
            encoding="utf-8",
            capture_output=True,
            timeout=10  # 添加超时防止卡死
        )

        # 检查返回码
        if result.returncode == 0:
            data = json.loads(result.stdout.strip() if result.stdout else "{}")
            return jsonify({
                "success": True,
                "code_length": len(source_code),
                "data": data,
            })
        else:
            # 失败 - stderr可能包含错误信息
            error_message = result.stderr if result.stderr else "编译过程出错"
            return jsonify({
                "success": False,
                "error": error_message,
                "returncode": result.returncode,
                "raw_stderr": result.stderr,
                "raw_stdout": json.loads(result.stdout)
            }), 400

    except KeyError:
        return jsonify({"success": False, "error": "缺少code字段"}), 400
    except subprocess.TimeoutExpired:
        return jsonify({"success": False, "error": "处理超时"}), 408
    except Exception as e:
        return jsonify({"success": False, "error": f"服务器内部错误: {str(e)}"}), 500


@app.route("/pcode", methods=["POST"])
def getPcode():
    try:
        source_code = request.json['code']
        result = subprocess.run(
            ["./output/exe/pcode"+(".exe" if is_windows() else "")],
            input=source_code,
            text=True,
            encoding="utf-8",
            capture_output=True,
            timeout=10  # 添加超时防止卡死
        )

        # 检查返回码
        if result.returncode == 0:
            data = list(map(str,result.stdout.split('\n')))
            return jsonify({
                "success": True,
                "code_length": len(source_code),
                "pcode": data,
            })
        else:
            # 失败 - stderr可能包含错误信息
            error_message = result.stderr if result.stderr else "编译过程出错"
            return jsonify({
                "success": False,
                "error": error_message,
                "returncode": result.returncode,
                "raw_stderr": result.stderr,
                "raw_stdout": json.loads(result.stdout)
            }), 400
    except KeyError:
        return jsonify({"success": False, "error": "缺少code字段"}), 400
    except subprocess.TimeoutExpired:
        return jsonify({"success": False, "error": "处理超时"}), 408
    except Exception as e:
        return jsonify({"success": False, "error": f"服务器内部错误: {str(e)}"}), 500

if __name__ == "__main__":
    app.run(debug=True)
