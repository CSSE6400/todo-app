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
            'checked' => true,
            'description' => 'Complete CSSE6400 Prac 1'
        ]);
        Todo::create([
            'checked' => true,
            'description' => 'Complete CSSE6400 Prac 2'
        ]);
        Todo::create([
            'checked' => true,
            'description' => 'Complete CSSE6400 Prac 3'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Complete CSSE6400 Prac 4'
        ]);
        Todo::create([
            'checked' => true,
            'description' => 'Joined the CSSE6400 Slack'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Attended Lecture 1 of CSSE6400'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Attended Lecture 2 of CSSE6400'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Attended Lecture 3 of CSSE6400'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Attended Lecture 4 of CSSE6400'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Attended Braes tutorial'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Read Braes handouts'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Book a dental appointment'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Cancel car rego'
        ]);
        Todo::create([
            'checked' => false,
            'description' => 'Ask for a raise'
        ]);
        for($i = 0; $i < 10; $i++) {
            Todo::create([
                'checked' => false,
                'description' => "I am a task $i"
            ]);
        }
    }
}
