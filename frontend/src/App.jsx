import React from 'react';
import TodoList from './components/TodoList';
import ImageUpload from './components/ImageUpload';
import ImageList from './components/ImageList';
import './App.css';

function App() {
  const serverHostname = import.meta.env.VITE_SERVER_HOSTNAME || '';
  console.log(serverHostname)

  return (
    <div className="App">
<section className="title-banner py-4 bg-success text-white" id="title-banner">
      <div className="container">
        <div className="row">
          <h4>Todo Image Gallery</h4>
        </div>
      </div>
    </section>
      <main>
        <TodoList />
        <ImageUpload />
        <ImageList />
      </main>
      <footer>
        <p>&copy; 2024 My To-Do App</p>
        <p>This app is running on: <strong>{serverHostname.toString()}</strong></p>
      </footer>
    </div>
  );
}

export default App;