<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SupplementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json($request->user()->supplements()->orderBy('name')->get());
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'        => 'required|string|max:255',
            'kind'        => 'required|in:supplement,medication,herbal',
            'dose'        => 'required|string|max:100',
            'form'        => 'required|string|max:50',
            'stock_units' => 'required|integer|min:0',
            'frequency'   => 'required|string|max:50',
            'times'       => 'required|array',
            'times.*'     => 'string|regex:/^\d{2}:\d{2}$/',
            'with_food'   => 'boolean',
            'reminder_on' => 'boolean',
            'track_stock' => 'boolean',
            'note'        => 'nullable|string',
        ]);

        $supplement = $request->user()->supplements()->create($data);
        return response()->json($supplement, 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        return response()->json($request->user()->supplements()->findOrFail($id));
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $supplement = $request->user()->supplements()->findOrFail($id);
        $supplement->update($request->validate([
            'name'        => 'sometimes|string|max:255',
            'dose'        => 'sometimes|string|max:100',
            'stock_units' => 'sometimes|integer|min:0',
            'times'       => 'sometimes|array',
            'with_food'   => 'sometimes|boolean',
            'reminder_on' => 'sometimes|boolean',
        ]));
        return response()->json($supplement);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $request->user()->supplements()->findOrFail($id)->delete();
        return response()->json(null, 204);
    }

    // POST /api/supplements/{id}/intake
    public function recordIntake(Request $request, int $id): JsonResponse
    {
        $supplement = $request->user()->supplements()->findOrFail($id);
        $data = $request->validate(['taken_at' => 'required|date']);

        $takenAt = \Carbon\Carbon::parse($data['taken_at']);
        $dayStart = $takenAt->copy()->startOfDay();
        $dayEnd   = $takenAt->copy()->endOfDay();

        $intake = $supplement->intakes()
            ->whereBetween('planned_at', [$dayStart, $dayEnd])
            ->first();

        if ($intake) {
            $intake->update(['taken_at' => $takenAt, 'skipped' => false]);
        } else {
            $intake = $supplement->intakes()->create([
                'user_id'    => $request->user()->id,
                'planned_at' => $dayStart,
                'taken_at'   => $takenAt,
            ]);
        }

        return response()->json($intake);
    }
}
