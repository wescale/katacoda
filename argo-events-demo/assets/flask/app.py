from flask import Flask, render_template, request
import flask

import os, json

INSIDE_OUT_FOLDER = os.path.join('static', 'inside_out')

app = Flask(__name__, static_url_path="/flask/static", static_folder="static")
app.config['INSIDE_OUT_FOLDER'] = INSIDE_OUT_FOLDER
app_blueprint = flask.Blueprint("blueprint", __name__)

image_name = 'sadness'

@app_blueprint.route('/')
def show_index():
    global image_name
    full_filename = os.path.join(app.config['INSIDE_OUT_FOLDER'], image_name + '.jpg')
    return render_template("index.html", user_image = full_filename)

@app_blueprint.route('/admin', methods=['POST'])
def change_image():
    global image_name
    request_data =  request.get_data()

    image_name = json.loads(request_data)['emotion'].lower()

    data = {"status": "success"}
    return data, 200


if __name__ == '__main__':
    app.register_blueprint(app_blueprint, url_prefix="/flask")
    app.run(host='0.0.0.0')
