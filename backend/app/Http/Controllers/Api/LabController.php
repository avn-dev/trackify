<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LabController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $limit = (int) $request->query('limit', 10);
        $measurements = $request->user()->labMeasurements()
            ->with('values')
            ->orderByDesc('taken_at')
            ->limit($limit)
            ->get();
        return response()->json($measurements);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'taken_at'    => 'required|date',
            'source'      => 'required|string|max:100',
            'raw_pdf_url' => 'nullable|url',
            'values'      => 'required|array|min:1',
            'values.*.marker'    => 'required|string|max:100',
            'values.*.value'     => 'required|numeric',
            'values.*.unit'      => 'required|string|max:30',
            'values.*.ref_low'   => 'required|numeric',
            'values.*.ref_high'  => 'required|numeric',
            'values.*.category'  => 'required|string|max:100',
        ]);

        $measurement = $request->user()->labMeasurements()->create([
            'taken_at'    => $data['taken_at'],
            'source'      => $data['source'],
            'raw_pdf_url' => $data['raw_pdf_url'] ?? null,
        ]);

        $measurement->values()->createMany($data['values']);
        $measurement->load('values');

        return response()->json($measurement, 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $measurement = $request->user()->labMeasurements()->with('values')->findOrFail($id);
        return response()->json($measurement);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $request->user()->labMeasurements()->findOrFail($id)->delete();
        return response()->json(null, 204);
    }
}
