<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Workout;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WorkoutController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $limit = (int) $request->query('limit', 20);
        $workouts = $request->user()->workouts()
            ->orderByDesc('started_at')
            ->limit($limit)
            ->get();
        return response()->json($workouts);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'plan_day'   => 'nullable|string|max:10',
            'started_at' => 'required|date',
            'ended_at'   => 'nullable|date',
            'volume_kg'  => 'required|numeric|min:0',
        ]);

        $workout = $request->user()->workouts()->create($data);
        return response()->json($workout, 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $workout = $request->user()->workouts()->findOrFail($id);
        return response()->json($workout);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $request->user()->workouts()->findOrFail($id)->delete();
        return response()->json(null, 204);
    }
}
