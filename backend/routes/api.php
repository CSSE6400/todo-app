<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\TodoController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// No Auth for this Prac

Route::get('/v1/todo', [TodoController::class, 'index']);
Route::post('/v1/todo', [TodoController::class, 'store']);
Route::get('/v1/todo/{id}', [TodoController::class, 'show']);
Route::put('/v1/todo/{id}', [TodoController::class, 'update']);
ROute::delete('/v1/todo/{id}', [TodoController::class, 'destroy']);
