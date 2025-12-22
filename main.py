import subprocess
from flask import Flask, request, jsonify
import json

app = Flask(__name__)

@app.route("/check", methods=["POST"])
def syntaxAnalysis():
    source_code = request.json["code"]

    result = subprocess.run(
        ["./lex.exe"],
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


if __name__ == "__main__":
    app.run(debug=True)
