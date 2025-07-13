import React, { useState } from 'react';
import axios from 'axios';

const ImageUpload = () => {
  const [file, setFile] = useState(null);
  const [message, setMessage] = useState('');

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
  };

  const handleUpload = async () => {
    if (!file) {
      setMessage('Please select a file to upload');
      return;
    }

    const formData = new FormData();
    formData.append('image', file);

    try {
      const response = await axios.post(`${import.meta.env.VITE_BACKEND_ENDPOINT}/api/upload`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      setMessage('File uploaded successfully');
    } catch (error) {
      setMessage('Error uploading file');
      console.error('Error:', error);
    }
  };

  return (
    <div className="card mt-3">
      <h4 className="card-header h4">Upload an Image</h4>
      <div className="input-group my-3 p-4">
  <input onChange={handleFileChange} type="file" className="form-control" ></input>
  <button className="btn btn-dark" onClick={handleUpload}>Upload</button>
</div>
      
      {message && <p>{message}</p>}
    </div>
  );
};

export default ImageUpload;