<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\WorkoutController;
use App\Http\Controllers\Api\RunController;
use App\Http\Controllers\Api\BodyMetricController;
use App\Http\Controllers\Api\LabController;
use App\Http\Controllers\Api\SupplementController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Trackify API Routes
|--------------------------------------------------------------------------
*/

// Health check (Docker healthcheck + uptime monitoring)
Route::get('/health', fn () => response()->json(['status' => 'ok']));

// Auth (public)
Route::prefix('auth')->group(function () {
    Route::post('/login',    [AuthController::class, 'login']);
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/apple',    [AuthController::class, 'apple']);
});

// Authenticated routes
Route::middleware('auth:sanctum')->group(function () {

    Route::get('/auth/me',     [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Workouts
    Route::apiResource('workouts', WorkoutController::class)->only(['index', 'store', 'show', 'destroy']);

    // Runs
    Route::apiResource('runs', RunController::class)->only(['index', 'store', 'show', 'destroy']);

    // Body metrics
    Route::get('body-metrics',         [BodyMetricController::class, 'index']);
    Route::post('body-metrics',        [BodyMetricController::class, 'store']);
    Route::delete('body-metrics/{id}', [BodyMetricController::class, 'destroy']);

    // Lab
    Route::apiResource('lab/measurements', LabController::class)->only(['index', 'store', 'show', 'destroy']);

    // Supplements
    Route::apiResource('supplements', SupplementController::class)->only(['index', 'store', 'show', 'update', 'destroy']);
    Route::post('supplements/{id}/intake', [SupplementController::class, 'recordIntake']);
});
