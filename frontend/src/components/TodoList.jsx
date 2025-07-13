import React, { useState, useEffect } from 'react';
import axios from 'axios';
import TodoItem from './TodoItem';

const TodoList = () => {
  const [todos, setTodos] = useState([]);
  const [newTodo, setNewTodo] = useState('');

  useEffect(() => {
    axios.get(`${import.meta.env.VITE_BACKEND_ENDPOINT}/api/todos`)
      .then(response => setTodos(response.data))
      .catch(error => console.error('Error fetching todos:', error));
  }, []);

  const addTodo = () => {
    axios.post(`${import.meta.env.VITE_BACKEND_ENDPOINT}/api/todos`, { text: newTodo })
      .then(response => setTodos([...todos, response.data]))
      .catch(error => console.error('Error adding todo:', error));
    setNewTodo('');
  };

  const deleteTodo = (id) => {
    axios.delete(`${import.meta.env.VITE_BACKEND_ENDPOINT}/api/todos/${id}`)
      .then(() => setTodos(todos.filter(todo => todo._id !== id)))
      .catch(error => console.error('Error deleting todo:', error));
  };
  return (
    <div className="container">
      <div className="row">
        <div className="col-sm">
        <div className="input-group mb-3">
        <input
        type="text"
        value={newTodo}
        className="form-control"
        placeholder="Add new todo Item"
        onChange={(e) => setNewTodo(e.target.value)}
      />
      <button className="btn btn-dark" onClick={addTodo}>Add Task</button>
</div>
        </div>
      </div>
      
      <div className="card mt-3">
      <h5 className="card-header h5">To do List</h5>
      <ul className="list-group">
        {Array.isArray(todos) && todos.map(todo => (
          <TodoItem key={todo._id} todo={todo} onDelete={deleteTodo} />
        ))}
        </ul>
      </div>
      </div>
  );
};

export default TodoList;