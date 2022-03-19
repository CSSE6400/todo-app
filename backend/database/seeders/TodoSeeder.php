<?php

namespace Database\Seeders;

use App\Models\Todo;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Seeder;

class TodoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        Todo::create([
            'checked' => false,
            'description' => 'Complete CSSE6400 Prac 3'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Hello World'
        ]);
    }
}
