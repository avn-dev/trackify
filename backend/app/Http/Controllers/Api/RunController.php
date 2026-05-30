<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RunController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $limit = (int) $request->query('limit', 20);
        $runs = $request->user()->runs()
            ->orderByDesc('started_at')
            ->limit($limit)
            ->get();
        return response()->json($runs);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'started_at'  => 'required|date',
            'ended_at'    => 'required|date',
            'distance_m'  => 'required|numeric|min:0',
            'duration_s'  => 'required|integer|min:0',
            'gain_m'      => 'nullable|numeric|min:0',
            'polyline'    => 'nullable|string',
            'splits_json' => 'nullable|string',
        ]);

        $run = $request->user()->runs()->create($data);
        return response()->json($run, 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $run = $request->user()->runs()->findOrFail($id);
        return response()->json($run);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $request->user()->runs()->findOrFail($id)->delete();
        return response()->json(null, 204);
    }
}
