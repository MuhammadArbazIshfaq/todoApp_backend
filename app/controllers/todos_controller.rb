class TodosController < ApplicationController
  def index
    render json: @current_user.todos
  end

  def create
    todo = @current_user.todos.build(todo_params)
    if todo.save
      render json: todo, status: :created
    else
      render json: { errors: todo.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    todo = @current_user.todos.find(params[:id])
    if todo.update(todo_params)
      render json: todo
    else
      render json: { errors: todo.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    todo = @current_user.todos.find(params[:id])
    todo.destroy
    render json: { message: "Todo deleted" }
  end

  private

  def todo_params
    params.permit(:title, :description, :completed)
  end
end
