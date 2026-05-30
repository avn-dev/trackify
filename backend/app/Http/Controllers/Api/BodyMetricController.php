<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BodyMetricController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $type  = $request->query('type');
        $limit = (int) $request->query('limit', 50);

        $query = $request->user()->bodyMetrics()->orderByDesc('ts')->limit($limit);
        if ($type) { $query->where('type', $type); }

        return response()->json($query->get());
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'ts'     => 'required|date',
            'type'   => 'required|string|max:50',
            'value'  => 'required|numeric',
            'method' => 'nullable|string|max:50',
        ]);

        $metric = $request->user()->bodyMetrics()->create($data);
        return response()->json($metric, 201);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $request->user()->bodyMetrics()->findOrFail($id)->delete();
        return response()->json(null, 204);
    }
}
