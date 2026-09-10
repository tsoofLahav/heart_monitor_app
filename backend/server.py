from flask import Flask, jsonify
from video_route import setup_video_route
from experiment_routes import experiment_bp
import os


app = Flask(__name__)

setup_video_route(app)
app.register_blueprint(experiment_bp, url_prefix="/data")


@app.route("/", methods=["GET"])
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "OK"}), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
