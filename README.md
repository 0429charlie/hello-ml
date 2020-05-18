hello-ml
===
First attempt on creating ML model on cloud. Can be deploy on AWS VM or GCP Cloud Run or the equivalent. It listen for API request. The request should include the image file. It then run the image through downloaded resnet34 model and return the prediction through API.<br>

API Format
---
From the client, we use react-native-image-picker library for picking the image. The image picker is call as following.<br>
```
let options = {
    title: 'Select Image',
    customButtons: [
        {name: 'customOptionKey', title: 'Choose Photo from Custom Option'},
    ],
    storageOptions: {
        skipBackup: true,
        path: 'images',
    },
};
ImagePicker.showImagePicker(options, response => {
    if (response.didCancel) {
        console.log('User cancelled image picker');
    } else if (response.error) {
        console.log('ImagePicker Error: ', response.error);
    } else if (response.customButton) {
        console.log('User tapped custom button: ', response.customButton);
        alert(response.customButton);
    } else {
        console.log(response);
    }
});
```
the response is then in the form of:<br>
```
 {"data": base64 string,"fileName": string,"fileSize": int,"height": int,"isVertical": bool,"orininalRotation": 0,"path": string,"timestamp": DateTime,"type": string,"uri": string,"width": int}<br>
```
Next, this response is then encoded with formData as follow (note that response is the same response as above)<br>
```
import FormData from 'form-data';
const formData = new FormData();
formData.append('photo', response);
```
Then sent to the server using axio<br>
```
import axios from 'axios';
await axios
    .post('API_url', {formData})
    .then(res => {
        console.log(res.data);
    });
```
In the server side, we get request which is in the from of:<br>
```
{'formData': {'_parts': [['photo', {'height': int, 'width': int, 'type': string, 'fileName': string, 'path': string, 'fileSize': int, 'data': base63 string, 'uri': string, 'isVertical': bool, 'originalRotation': int, 'timestamp': DateTime}]]}}
```
Note that it start with the key 'formData' then '_parts'. Inside the '_parts', we get a list where each element is the a tuple generated from each formData.append(key, value). In this case, we only called formData.append('photo', response) once so we only have 1 element with first of tuple to be the key 'photo' and second is the response that we get from the image-picker library (the order of the key in the response might be different after encoding with formData but the content are the same).<br>

To parse the request with the above format, do the following:<br>
```
from flask import Flask, request, jsonify
img64 = request.get_json()['formData']['_parts'][0][1]['data']
```
get_json() parse the request into a readable format (from byte representation), then we access the first key 'formData', then the second '_parts'. After that, we access the first element (which is the first dataForm.append() call in frontend) using [0]. Note that using [0][0] will give us the key of the first dataForm.append(key,value), [1][0] will giave us the key of the second dataForm.append(key,value) and so on. Thus, [0][1] above gives us the value of the first dataForm.append(key,value) from the frontend!!Now we have the value which is the response we got from image-picker in frontend. So the 'data' field of it is the base64 string representation of the image!!<br>

We then decode the base64.<br>
```
import base64
imgdata = base64.b64decode(img64)
``` 
Then convert it into ByteIO in order to further convert it to PIL image.<br>
```
import io
from PIL import Image
buf = io.BytesIO(imgdata)
PIL_image = Image.open(buf)
```
Note that we can also save the file locally after decoding the base64 representation!!<br>
```
filename = 'temp.jpg'
with open(filename, 'wb') as f:
    f.write(imgdata)
```
We can get the correct extension for the filename above by getting the extension from request (request.get_json()['formData']['_parts'][0][1]['type'] gives 'image/jpeg' and request.get_json()['formData']['_parts'][0][1]['fileName'] gives 'filename.extension' for example).<br>

Now we can do stuff with the PIL image!! The return for this API is a simple string which can get get by res.data back in React Native front-end. However, we can also encode it into json using jsonify() and return a json!!<br>

Lastly, following are some useful command to investigate the request received. <br>
```
print(request.mimetype)
print(request.content_type)
print(request.get_json())
print(request.get_json()['formData']['_parts'][0][1]['data'])
```

Set up Dev Environment
---
This project is created using Pycharm, an IDE by JetBrains. The following is a way to create dev environment in Pycharm but any setup with Python3, Flask, and Pytorch will work.<br>
1. Download Anaconda.<br>
2. Create environment that we need. This can be done with the Anacaonda UI.<br>
3. Install the required package using Anaconda prompt. The following is an example of installing flask.<br>
    ```
    conda env list    # List all the environment
    activate Pytorch  # Activate the chosen environment (Pytorch in this case)
    pip install Flask   #install package as instructed on official website
    ```
4. Create new project and set the interpreter using the existing interpreter. You should see the environment you created in conda to choose from.<br>

*For cloning the project, just clone normally and set the interpreter later.<br>

Test Locally
---
In Pycharm, the program can be launch by clicking the run button. If not using Pycharm, just run python hello-ml.py in the project root.<br>

However, before running, note the port you are running on. For example, locate something like app.run(host='0.0.0.0', port=80) in your main function. It mean you are exposing endpoint on port 80. Then in the frontend, use http://[local ip]:[port]/[endpoint] for the fetch url. local ip can be acquired by typing ipconfig in command prompt.<br>

Deploy on GCP using Cloud Run
---
Can be done with the following:<br>
1.	Open cloud shell<br>
2.	git clone the project<br>
3.	cd into the project<br>
4.	Get your project id<br>
    gcloud config get-value project<br>
5.	Build container image.<br>
    gcloud builds submit --tag gcr.io/[PROJECT-ID]/[app_name]<br>
6.	Deploy Cloud Run using the UI from GCP<br>
6.1 Will be prompt for service name and region, and please allow authentication.<br>
6.2 Note that container port must match to port in Docker file.<br>
6.3 Also don’t forget to allocate enough memory.<br>
7.	On success, note the service URL.<br>

Deploy on AWS EC2 (VM) or equivalent
---
1.	Set up and es2 instance (from ec2 select Key Pairs).<br>
2.	SSH into the created instance.<br>
2.1 Use the right url. For example, ec2-user@ec2-15-223-118-63.ca-central-1.compute.amazonaws.com<br>
3.	Clone the project<br>
4.	Run docker build -t [project name] .<br>
5.	Run docker run -p 80:80 [project name]<br>
6.	Now, the backend is ready and listening!<br>

For generating key for putty:<br>
Puttygen->load->save private key<br>
