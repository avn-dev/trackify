<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Extend users table with apple_id
        Schema::table('users', function (Blueprint $table) {
            $table->string('apple_id')->nullable()->unique()->after('id');
        });

        Schema::create('workouts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('plan_day')->nullable();
            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();
            $table->double('volume_kg')->default(0);
            $table->timestamps();
        });

        Schema::create('workout_sets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('workout_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('exercise_id');
            $table->unsignedSmallInteger('set_no');
            $table->double('weight_kg');
            $table->unsignedSmallInteger('reps');
            $table->unsignedTinyInteger('rir')->nullable();
            $table->timestamp('done_at');
            $table->timestamps();
        });

        Schema::create('exercises', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('muscle_group');
            $table->string('demo_video_url')->nullable();
            $table->timestamps();
        });

        Schema::create('runs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamp('started_at');
            $table->timestamp('ended_at');
            $table->double('distance_m');
            $table->unsignedInteger('duration_s');
            $table->double('gain_m')->default(0);
            $table->longText('polyline')->nullable(); // base64-encoded coordinate data
            $table->json('splits_json')->nullable();  // [{km, pace_sec_per_km, avg_bpm}]
            $table->timestamps();
        });

        Schema::create('body_metrics', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamp('ts');
            $table->string('type');        // weight | bodyFat | chest | waist | ...
            $table->double('value');
            $table->string('method')->nullable();
            $table->timestamps();
        });

        Schema::create('lab_measurements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamp('taken_at');
            $table->string('source')->default('Manuell');
            $table->string('raw_pdf_url')->nullable();
            $table->timestamps();
        });

        Schema::create('lab_values', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lab_measurement_id')->constrained()->cascadeOnDelete();
            $table->string('marker');
            $table->double('value');
            $table->string('unit');
            $table->double('ref_low');
            $table->double('ref_high');
            $table->string('category');
            $table->timestamps();
        });

        Schema::create('supplements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('kind')->default('supplement'); // supplement | medication | herbal
            $table->string('dose');
            $table->string('form')->default('Kapsel');
            $table->integer('stock_units')->default(0);
            $table->string('frequency')->default('daily');
            $table->json('times');          // ["07:30", "21:00"]
            $table->boolean('with_food')->default(false);
            $table->boolean('reminder_on')->default(true);
            $table->boolean('track_stock')->default(true);
            $table->text('note')->nullable();
            $table->timestamps();
        });

        Schema::create('supplement_intakes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('supplement_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamp('planned_at');
            $table->timestamp('taken_at')->nullable();
            $table->boolean('skipped')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('supplement_intakes');
        Schema::dropIfExists('supplements');
        Schema::dropIfExists('lab_values');
        Schema::dropIfExists('lab_measurements');
        Schema::dropIfExists('body_metrics');
        Schema::dropIfExists('runs');
        Schema::dropIfExists('workout_sets');
        Schema::dropIfExists('exercises');
        Schema::dropIfExists('workouts');
        Schema::table('users', fn (Blueprint $t) => $t->dropColumn('apple_id'));
    }
};
