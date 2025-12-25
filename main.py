import subprocess
from flask import Flask, request, jsonify
import json
from flask_cors import CORS
import sys
from quadruple import PcodeToQuadsTranslator

def is_windows():
    return sys.platform.startswith("win")


app = Flask(__name__)
CORS(app)



@app.route("/keyword",methods=['GET'])
def get_keyword():
    """
    T_IntConstant T_Identifier
    T_Void T_Int T_While T_If T_Else T_Return T_Explain T_Break T_Continue 
    T_Le T_Ge T_Eq T_Ne T_And T_Or T_inputInt T_outputInt T_Power
    """
    return jsonify({
        "T_IntConstant": "整型常量",
        "T_Identifier": "标识符（变量名或函数名）",

        "T_Void": "空类型",
        "T_Int": "整型类型",
        "T_While": "while 循环语句",
        "T_If": "条件判断 if",
        "T_Else": "条件分支 else",
        "T_Return": "函数返回语句",
        "T_Explain": "注释或说明关键字",
        "T_Break": "跳出循环",
        "T_Continue": "跳过本次循环",

        "T_Le": "小于等于运算符",
        "T_Ge": "大于等于运算符",
        "T_Eq": "等于比较运算符",
        "T_Ne": "不等于比较运算符",
        "T_And": "逻辑与运算符",
        "T_Or": "逻辑或运算符",

        "T_inputInt": "输入整数函数",
        "T_outputInt": "输出整数函数",
        "T_Power": "幂运算函数"
    })


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
            data = result.stdout
            print(data)
            pt= PcodeToQuadsTranslator()
            print(pt.translate(data))
            return jsonify({
                "success": True,
                "code": len(source_code),
                "pcode": list(map(str,data.split('\n'))),
                "quads":json.loads(json.dumps(pt.translate(data)))
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

@app.route("/ast", methods=["POST"])
def getAST():
    try:
        source_code = request.json['code']
        result = subprocess.run(
            ["./output/exe/ast"+(".exe" if is_windows() else "")],
            input=source_code,
            text=True,
            encoding="utf-8",
            capture_output=True,
            timeout=10  # 添加超时防止卡死
        )

        # 检查返回码
        if result.returncode == 0:
            data = result.stdout
            print(data)
            # pt= PcodeToQuadsTranslator()
            # print(pt.translate(data))
            return jsonify({
                "success": True,
                "code": len(source_code),
                "data": json.loads(data),
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

@app.route("/asm", methods=["POST"])
def getASM():
    try:
        source_code = request.json['code']
        result = subprocess.run(
            ["./output/test/acc"+(".exe" if is_windows() else "")],
            input=source_code,
            text=True,
            encoding="utf-8",
            capture_output=True,
            timeout=10  # 添加超时防止卡死
        )

        # 检查返回码
        if result.returncode == 0:
            data = result.stdout
            print(data)
            # pt= PcodeToQuadsTranslator()
            # print(pt.translate(data))
            return jsonify({
                "success": True,
                "code": len(source_code),
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

if __name__ == "__main__":
    app.run(debug=True)