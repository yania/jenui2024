# using flask_restful 
# https://flask-restful.readthedocs.io/en/latest/
from flask import Flask, jsonify, request 
from flask_restful import Resource, Api 
from flask_httpauth import HTTPBasicAuth
import subprocess

auth = HTTPBasicAuth()

# creating the flask app 
app = Flask(__name__)
# creating an API object 
api = Api(app) 

# making a class for a particular resource 
# the get, post methods correspond to get and post requests 
# they are automatically mapped by flask_restful. 
# other methods include put, delete, etc. 
class MySonarqubeWebHook(Resource): 

	# corresponds to the GET request. 
	# this function is called whenever there 
	# is a GET request for this resource 
	def get(self): 

		return jsonify({'message': 'Webhook for sonarqube on premises'}) 

	# Corresponds to POST request
	@auth.login_required 
	def post(self): 
		try:	
			data = request.get_json()	 
			server = data.get('serverUrl')
			project  = data.get('project')
			key = project.get('key')
			user_login = key.split('-')[-1].split(':')[0]
			#print(user_login)
			#print(key)
			currentDirectory='/your/leaderboard/sonarwebhookservice'
			subprocess.run(["Rscript","--vanilla", currentDirectory+"/contest.R", key], check=True)
			responseObject = { 
				'status': 'success',
         			'message': 'Successfully registered.'
        		}
			response = jsonify(responseObject)
			response.status_code = 201
			return response

		except subprocess.CalledProcessError:
			responseObject = {
				'status': 'error',
				'message': 'Bad project key'
			}
			error_response = jsonify(responseObject)
			error_response.status_code = 400
			return error_response
		except Exception as e:
			responseObject = {
				'status' : 'error',
				'message': e
			}
			error_response = jsonify(responseObject)
			error_response.status_code = 500
			return error_response

	@auth.verify_password
	def verify_password(username, password):

    		# implements here your authorization
    		return True

# another resource to calculate the square of a number 
# We use this for testing the web server independently from sonarqube webhook and authorization :-D
class Square(Resource): 

	def get(self, num): 

		return jsonify({'square': num**2}) 


# adding the defined resources along with their corresponding urls 
api.add_resource(MySonarqubeWebHook, '/sonarqubewebhook') 
api.add_resource(Square, '/square/<int:num>') 


# driver function 
if __name__ == '__main__': 

	app.run(debug = True)

