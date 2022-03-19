<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class TodoTest extends TestCase
{

    public function test_paged_list()
    {
        $response = $this->get('/api/v1/todo');

        $response->assertStatus(200);
    }

    public function test_get()
    {
        $response = $this->get('/api/v1/todo/HelloBraeWebbHere');
        $response->assertStatus(500);

        $response = $this->get('/api/v1/todo/1');
        $response
            ->assertStatus(200)
            ->assertJson([
                'checked' => false,
                'description' => 'Complete CSSE6400 Prac 3'
            ]);
    }

    public function test_create()
    {
        $response = $this->postJson('/api/v1/todo', [
            'checked' => false,
            'description' => 'Order some more IKEA lights'
        ]);

        $response
            ->assertStatus(201)
            ->assertJson([
                'checked' => false,
                'description' => 'Order some more IKEA lights'
            ]);

        $response = $this->postJson('/api/v1/todo', [
            'checked' => true,
            'description' => 'Order some more IKEA lights'
        ]);

        $response
            ->assertStatus(201)
            ->assertJson([
                'checked' => true,
                'description' => 'Order some more IKEA lights'
            ]);
    }

    public function test_invalid_create()
    {
        $response = $this->postJson('/api/v1/todo', [
            'checked' => false,
            'description' => ''
        ]);
        $response->assertStatus(422);

        $response = $this->postJson('/api/v1/todo', [
            'checked' => false,
        ]);
        $response->assertStatus(422);
    }

    public function test_checking()
    {
        $response = $this->postJson('/api/v1/todo', [
            'checked' => false,
            'description' => 'Order some more IKEA lights'
        ]);

        $response
            ->assertStatus(201)
            ->assertJson([
                'checked' => false
            ]);

        $id = $response['id'];
        $response = $this->putJson("/api/v1/todo/{$id}", [
            'checked' => true,
            'description' => $response['description']
        ]);

        $response
            ->assertStatus(200)
            ->assertJson([
                'checked' => true
            ]);

        $response = $this->putJson("/api/v1/todo/{$id}", [
            'checked' => false,
            'description' => $response['description']
        ]);

        $response
            ->assertStatus(200)
            ->assertJson([
                'checked' => false
            ]);
    }

    public function test_description()
    {
        $response = $this->postJson('/api/v1/todo', [
            'checked' => false,
            'description' => 'Order some more IKEA lights'
        ]);

        $response
            ->assertStatus(201)
            ->assertJson([
                'checked' => false,
                'description' => 'Order some more IKEA lights'
            ]);

        $id = $response['id'];
        $response = $this->putJson("/api/v1/todo/{$id}", [
            'checked' => $response['checked'],
            'description' => 'Order Tradfri lights'
        ]);

        $response
            ->assertStatus(200)
            ->assertJson([
                'checked' => false,
                'description' => 'Order Tradfri lights'
            ]);
    }

    public function test_updating_both()
    {
        $response = $this->postJson('/api/v1/todo', [
            'checked' => false,
            'description' => 'Order some more IKEA lights'
        ]);

        $response
            ->assertStatus(201)
            ->assertJson([
                'checked' => false,
                'description' => 'Order some more IKEA lights'
            ]);

        $id = $response['id'];
        $response = $this->putJson("/api/v1/todo/{$id}", [
            'checked' => true,
            'description' => 'Order Tradfri lights'
        ]);

        $response
            ->assertStatus(200)
            ->assertJson([
                'checked' => true,
                'description' => 'Order Tradfri lights'
            ]);
    }

    public function test_delete()
    {
        $response = $this->postJson('/api/v1/todo', [
            'checked' => false,
            'description' => 'Order some more IKEA lights'
        ]);

        $response
            ->assertStatus(201)
            ->assertJson([
                'checked' => false,
                'description' => 'Order some more IKEA lights'
            ]);

        $response = $this->delete("/api/v1/todo/{$response['id']}");

        $response
            ->assertStatus(200)
            ->assertJson([
                'message' => 'OKAY'
            ]);
    }

    public function test_bad_delete()
    {
        $response = $this->postJson('/api/v1/todo', [
            'checked' => false,
            'description' => 'Order some more IKEA lights'
        ]);

        $badID = $response['id'] + 100;
        $response = $this->delete("/api/v1/todo/{$badID}");

        $response
            ->assertStatus(200)
            ->assertJson([
                'message' => 'OKAY'
            ]);
    }
}
