---
title: Metro Awakening
classes: wide centered
header:
  image: /assets/portfolio/impact/hero.png
card:
  image: /assets/portfolio/impact/teaser.png
  title: Metro Awakening
  from: Sept. 2022
  to: Dec. 2024
  excerpt: A story-driven first person adventure built exclusively for VR that blends atmospheric exploration, stealth and combat.
  tags:
  - tag: VR Game of the Year
    image: /assets/images/icons/steam.svg
    link: https://store.steampowered.com/steamawards/2024#VRGameoftheYear
  - tag: Best VR/AR - Nominee
    image: /assets/images/icons/the_game_awards.svg
    link: https://thegameawards.com/
  - Unreal Engine 5
  - C++
  - Vertigo Games
---

As a member of the 'Feature Team', I worked on basically every player-facing gameplay mechanic.

<mark>TODO</mark>

{% capture_markdown firearms %}

One of the core pillars of Metro Awakening was "Tactile Stealth Shooter Action". The goal was for the all the interactions to feel as tactile, mechanical and realistic as they could possibly be, while also being accessible and frictionless to use. This really came down to focussing on the details of how the weapons work mechanically and how you interact with them. These details might seem small, but they go a long way in selling the idea that you're actually using a firearm.

### Reloading

All firearms in Metro Awakening need to be reloaded manually, to make the experience as realistic and tactile as possible. To make this as accessible as possible for players, we implemented multiple ways to reload each weapon. The Kalashnikov, for example, has 3 reload methods:

#### 1. Pulling the magazine out  
By simply grabbing the magazine, players can pull out the magazine and throw it to the side, before inserting a new magazine. During development, we initially ejected the magazine from the weapon the moment the player grabbed it. However, some playtesters (who were less familiar with guns) tried to grab the magazine as a foregrip.  
To alleviate this issue, I changed the system to allow players to hold the magazine and only eject it if they moved their hand far enough away. I even made sure that the recoil from the weapon would not cause the magazine to eject.  
Holding the weapon this way does not apply the lower 2-handed recoil though, to signify that this is not the intended way to hold the weapon.  
Another benefit of this change was that the interaction now felt more tactile, as you needed to perform a physical motion to eject the magazine.

<video autoplay loop muted controls width="100%">
  <source src="/assets/portfolio/impact/firearms/kalashnikov-reload.mp4" type="video/mp4">
</video>

#### 2. Inserting while a magazine is loaded  
During development, a lot of playtesters would incorrectly grab a magazine from their inventory first, without having ejected the magazine first. Without a free hand to eject the magazine, they would usually end up fumbling around and accidentally dropping their full magazine. This was clearly not as frictionless as it needed to be.  
To fix this, I simply allowed players to insert the magazine while another magazine was already loaded. The hand plays an animation where the thumb hits the magazine release latch, after which the old magazine ejects and the new one is inserted.

<video autoplay loop muted controls width="100%">
  <source src="/assets/portfolio/impact/firearms/kalashnikov-reload-filled-chamber.mp4" type="video/mp4">
</video>

#### 3. Knocking the magazine out  
The last way to eject the magazine, is to knock the magazine out of the firearm using another magazine. The goal for this interaction was to feel cool, but the way the magazine was spinning initially didn't look cool. It was spinning very quickly around it's shortest axis, while I wanted it to spin end over end. To fix this, I calculated the angular velocity manually while clamping the impact point onto the axis I didn't want the magazine to spin around. This ensures that the resulting angular velocity won't rotate around that axis.  
![](/assets/portfolio/impact/firearms/kalashnikov-knock-out-angular-velocity.png)  

<div style="container-type: inline-size">
  <div class="video-grid__responsive">
    <div style="width: 100%; text-align: center;">
      <video autoplay muted loop width="100%">
        <source src="{{ '/assets/portfolio/impact/firearms/kalashnikov-reload-knock-out-before.mp4' | relative_url }}" type="video/mp4">
      </video>
      <em>Before</em>
    </div>
    <div style="width: 100%; text-align: center;">
      <video autoplay muted loop width="100%">
        <source src="{{ '/assets/portfolio/impact/firearms/kalashnikov-reload-knock-out-after.mp4' | relative_url }}" type="video/mp4">
      </video>
      <em>After</em>
    </div>
  </div>
</div>

### Chambering

All firearms in Metro Awakening need to be chambered manually, to make the experience as realistic and tactile as possible.

The chambering of the Tokerev is rather detailed. There are 3 moving parts, the slide, slide latch and hammer.  
The player is able to grab the slide and freely move it back an forth. Any chambered bullet gets ejected while pulling the slide backwards, and a new bullet gets chambered while moving the slide forwards. The movement of the slide also pushes the hammer down, eventually clicking into place when it's pushed far enough.  
When the player fires the weapon, the slide moves backwards to eject a bullet and push the hammer backwards. On the return, the slide chambers another bullet. Unless there's no other bullet, in which case the slide latch engages to hold the slide in place. At this point the player can insert a new magazine. After that they can disengage the slide latch with their thumb, using a button, or by grabbing the slide with their other hand.
In real life, firing a weapon requires the hammer to strike the bullet's primer. This adds a small delay, which I didn't want to have. So I made the weapon fire instantly instead. The hammer still moves forwards, but meets the slide rather quickly.

<video autoplay loop muted controls width="100%">
    <source src="/assets/portfolio/impact/firearms/tokarev-slide.mp4" type="video/mp4">
</video>

This realistic chambering approach did end up causing some issues. Since the weapon literally can't fire if a bullet hasn't been chambered yet, we ran into some timing issues where the Kalashniov's rpm was inconsistent and it could even jam.  
The first thing I did, was to make sure that the chambering was reliable, allowing it to move back and forth within a single frame.  
I then dove into our firing code, modifying it to make it shoot at a reliable rpm regardless of framerate. This even includes support for firing multiple bullets within a single frame, if necessary.

<video autoplay loop muted controls width="100%">
    <source src="/assets/portfolio/impact/firearms/kalashnikov-10x.mp4" type="video/mp4">
</video>

*Example of reliably firing an average of 2,2 bullets per frame, at 10x game speed.*

### Helsing Cylinder

Another cool weapon detail, is the Helsing's cylinder. This is a revolver style cylinder, filled with bolts instead of bullets, which can swing open to the side.  
We wanted the cylinder to spin, while it's swung open, to add some extra realism and interactivity. The cylinder switches between 2 rotation modes, based on how the bolts are loaded.

1. If the bolts are balanced, then the cylinder spins freely and eventually settles.
2. If the bolts are unbalanced, then the cylinder will wobble back and forth and eventually settle with the most weight at the bottom.

<video autoplay loop muted controls width="100%">
    <source src="/assets/portfolio/impact/firearms/helsing-reload.mp4" type="video/mp4">
</video>

We also added two ways of closing the cylinder, to make it more realistic and accessible. You can use your other hand to push the cylinder closed, or you can flick your wrist to close the cylinder.

{% endcapture_markdown %}

{% include card.html title="Firearms" image="/assets/portfolio/impact/firearms/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=firearms %}





{% capture_markdown hand_animations %}

Instead of simply making the fingers move as you press the buttons on your controller, I wanted them to blend into expressive poses. There are 3 inputs, the grip button, the trigger and the capacitive thumbsticks. With these 3 inputs you can create 8 unique combinations, 4 of which got a unique pose: thumbs up, pointing, ok sign and fist.  
The grip button and trigger also report how far the button is pressed, allowing me to smoothly blend between the poses. Since we have 3 degrees of freedom, I needed a 3 dimensional blend space. Unreal unfortunately doesn't have this, so I needed to implement my own. In my specific case, I knew the inputs would form a unit cube as the inputs are all between 0 and 1. Every corner of the cube had an accompanying hand pose. I was then able to divide that unit cube into 5 tetrahedra. Given a 3D input point, it was very simple to determine if it was inside a particular tetrahedron, as you can simply check the manhattan distance from the respective corner of the unit cube. Once I figured out the correct tetrahedron, I could use `FMath::ComputeBaryCentric3D` to find the 4D barycentric coordinate for the 3D input coordinate. The 4 values of the barycentric coordinate can then be used as the alpha values for the poses at the corners of the tetrahedron.  
This mimics the behavior of 2D blend spaces, but with an extra dimension. 2D blend spaces are divided into triangles, where a 3D barycentric coordinate represents the alpha values for the 3 animations at the corners of the triangle.

![](/assets/portfolio/impact/hand-animations/3d-blend-space.png)

<mark style = "background-color:magenta">Image: Cube split into tetrahedra (Interactive 3D animation?)</mark>  

Later in production, the request came in to add support for the finger tracking from the valve index controller.  
The first step was to convert the hand pose that OpenXR provides into 0 to 1 values that I can work with. I did this by summing the angles between all consecutive bones in a finger, to get a total `CurlAngle`. I then mapped this angle to a 0 to 1 range.  
I now had 5 inputs (fingers), instead of 3. Creating a 5D blend space, and dividing a 5D hypercube into 67 5-simplexes, was not going to be an option. So I took another approach.  
To animate the middle finger, ring finger and pinky separately, I redid the input calculation from before 2 more times, with the grip input forced to 0 and 1. I was then able to blend between these poses per finger, and use a layered blend to combine them. This kept the old expressive posses in place, while adding control for every individual finger.  
With these new inputs, I also wanted to add 3 new expressive poses: peace, flipping the bird and rock & roll. I calculated an alpha value for each pose, based on how close the input was to the desired input. Those 3 values then formed a 3D coordinate, which I clamped to a tetrahedron and then converted to barycentric coordinates again. I could then use this to smoothly blend from the regular hand poses to one of these expressive poses.

<div style="container-type: inline-size">
  <div class="video-grid__responsive">
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/hand-animations/hand-animations-game.mp4' | relative_url }}" type="video/mp4">
    </video>
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/hand-animations/hand-animations-controller.mp4' | relative_url }}" type="video/mp4">
    </video>
  </div>
</div>

It was really cool to see how players, and especially streamers, used these poses to express themselves. Using their fists to punch enemies, pointing at stuff, giving a thumbs up to show their approval and flipping the bird at whoever might deserve it.

{% endcapture_markdown %}

{% include card.html title="Hand Animations & Finger Tracking" image="/assets/portfolio/impact/hand-animations/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=hand_animations %}





{% capture_markdown hand_movement %}

The hand movement in Metro Awakening had the following requirements:
- The difference between the location and rotation of the controller and the in-game hand (hand parity) should be minimized.
- The hands should accurately collide with world geometry, without any clipping.
- Hands snapping, to a different location, should be minimized.
- Held objects should be included in the hand's collision/movement.

We chose to create a bespoke 'collision sweep' based system, instead of relying on physics, as this offered us more control and reliability. The system that I created goes through the following steps:

1. **Bounding Box Sweep**  
The goal of the system is for the hand to move from it's current location to the target location, at the controller. The first step is to gather all the colliders on the hand and held object into a single oriented bounding box. I then sweep this box to the target location. This saves a lot of performance, as players usually don't have their hands close to any world geometry.
2. **Sweeping all colliders**  
More precise sweeps are necessary if the bounding box did hit something. I sweep every collider on the hand and held object individually, keeping track of the closest hit.
3. **Resolving Penetration**  
Collision sweeps only support translations, not rotations. This means that I have to naively start moving the hand using it's new rotation. However, this usually leads to the hand overlapping with world geometry, which would be detected by the initial sweep.  
I wrote a custom depenetration algorithm, which is able to reliably move the hand's and held object's colliders into a non-overlapping position again. The hand is now free to move and the initial sweep can be reattempted again.
4. **Slide Sweep**  
If the first sweep hit something along the way, then I slide the hand across the surface that was hit. I simply redirect the movement delta based on the normal of the hit surface. This doesn't get us to the target location, but it does get us closer.
5. **Two-Wall Slide Sweep**  
If the slide sweep also hit something, then I recompute the movement delta based on both hit normals. This allows the system to handle corners and curves.

After these steps, the system has hopefully ended up close to the the target location. This doesn't always work out though. Very occasionally the depenetration might fail, which would cause the hand to be stuck. The hand might also be lodged behind something, which would cause hand parity loss.  
While I tried to avoid it, the only solution here is to snap the hand to a different location. This fallback resets the hand location to be at the camera location, from which the hand is moved to the target location again. This all happens in a single frame, so visually it looks like the hand instantly corrected itself to a new location.
In very rare occasions, this fallback can also fail. Especially if the player was holding a large weapon, or if the player tried to stick their hand through a wall. As a last fallback, the hand and held object go into a 'ghosting' state, showing a red outline. In this state the hand is unable to perform actions like grabbing, dropping or shooting. This prevents various exploits, like opening a one-way door from the wrong side by sticking your hand though the door.

<div style="container-type: inline-size">
  <div class="video-grid__responsive">
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/hand-movement/hand-movement.mp4' | relative_url }}" type="video/mp4">
    </video>
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/hand-movement/hand-movement-vislog.mp4' | relative_url }}" type="video/mp4">
    </video>
  </div>
</div>

{% endcapture_markdown %}

{% include card.html title="Hand Movement" image="/assets/portfolio/impact/hand-movement/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=hand_movement %}





{% capture_markdown hand_interaction %}

#### Interaction Socket

For hand interactions, you often see VR games use one of two approaches. They either use a single predetermined pose per grabbable object, which is limiting for the player. Or they use IK to create a dynamic hand pose, which usually doesn't look great.
We wanted the flexibility of an IK system, with the quality from dedicated poses. That's why we created the `Interaction Socket Component`. This component allows designers to assign multiple hand poses to a single object. The system then dynamically picks the best hand pose based on the distance and rotation of the pose.  
The system also supports rotating poses, and poses along a line. This makes it super easy to make it feel like you can really grab an object anywhere.

<video autoplay loop muted controls width="100%">
  <source src="/assets/portfolio/impact/hand-interaction/socket.mp4" type="video/mp4">
</video>

Additionally, the rotating poses can also be configured to rotate while the player is holding the object.

<video autoplay loop muted controls width="100%">
  <source src="/assets/portfolio/impact/hand-interaction/valve.mp4" type="video/mp4">
</video>

This system was a joined effort between me an [Hilko Janssen](https://hilkojj.nl/), who I was mentoring at the time.

#### World Interactions

We wanted the world interactions to feel tactile and to have a sense of resistance. This is difficult to do in VR, as you can't prevent the player from physically moving. To simulate resistance, we developed the `FrictionInteractionConstraint` component. The component allows for one axis of movement, either translation or rotation.  
While the player is interacting, we use various tricks to make it feel like the interaction has resistance. Every interaction can be configured with different hand movement scaling, hand interpolation speed and a curve that maps the hand movement to the visual movement. The curve allows us to make valves feel like they're stuck at the start, or to add a rachety feel to levers.  
The `FrictionInteractionConstraint` is derived from the `PhysicsConstraintComponent`. Once the player releases the interactable, the physics takes over. This allows players to throw a door shut with a swing.

<div style="container-type: inline-size">
  <div class="video-grid__responsive">
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/hand-interaction/planks.mp4' | relative_url }}" type="video/mp4">
    </video>
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/hand-interaction/supply-boxes.mp4' | relative_url }}" type="video/mp4">
    </video>
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/hand-interaction/levers.mp4' | relative_url }}" type="video/mp4">
    </video>
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/hand-interaction/valve-door.mp4' | relative_url }}" type="video/mp4">
    </video>
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/hand-interaction/doors.mp4' | relative_url }}" type="video/mp4">
    </video>
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/hand-interaction/pry-door.mp4' | relative_url }}" type="video/mp4">
    </video>
  </div>
</div>

{% endcapture_markdown %}

{% include card.html title="Hand Interaction" image="/assets/portfolio/impact/hand-interaction/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=hand_interaction %}





{% capture_markdown locomotion %}

To improve accessibility, one of the requirements was that the locomotion system needed support both stick and teleport locomotion. For teleport locomotion, using the NavMesh was an easy choice as a teleportation targeting surface. We also decided to use the NavMesh for stick locomotion, for 2 main reasons. Firstly, this setup guarantees that stick players are able to reach exactly the same places as teleport players. Secondly, the NavMesh is a smooth surface for the player to walk across, preventing any height jittering for the player camera.

The locomotion system was a joined effort between me and [Laurens Holst](https://www.grauw.nl/), who was my lead at the time.

### Journeys

There are various situations where the player needs to be automatically moved from A to B, like teleporting, jumping, step ups and ladder climbing. To implement all these movements, we created the `Journey` system. The idea is simple: Any system can construct a `Journey`, which consists of an array of `Motions`, which can then be executed by the `JourneyExecutionController`. Every `Motion` consists of a location and a rotation to move to, along with a new `Stance` and `LocomotionMode`. The `Journey` object also provides various utilities, like querying `Motions` by distance, or finding a `Motion` with a specific `LocomotionMode`.

While some systems fully construct a journey on their own, a lot of systems use the `JourneyCalculator`. This is a blueprint that iteratively tries to apply various `Motions`, guarded by various checks.  
The first thing the system tries, is to walk forwards along the NavMesh. If it fails, it tries if it can move if the player crouches.  
Beyond this point, the system will try various `Motions` which periodically go off the NavMesh. The system does however guarantee that the journey will always end on the NavMesh again, so that we end in a valid position from which the player can start moving again. The system also makes sure that there are no colliders blocking the path.  
The first off-NavMesh motion that the system checks, is to step up or down to a higher or lower NavMesh.  
The system then checks for `MotionTargets`, which are actors which implement an interface, allowing them to modify the `Journey`. A ladder can add `Motions` to climb up or down the ladder, and a door can add a `Motion` to position you at a comfortable distance to grab the door handle.  
Lastly, the system checks for horizontal and vertical jumps.

The nice thing about this system, is that it unifies a lot of behavior.  
Teleport targeting works by constructing a `Journey`, to show the visual of where the player will end up. Once the player executes the teleport, we can simply execute the `Journey`.  
Meanwhile, stick locomotion also runs the same `JourneyCalculator` logic, to allow it perform exactly the same off-NavMesh `Journeys` as the teleport locomotion.

<div style="container-type: inline-size">
  <div class="video-grid__responsive">
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/locomotion/stick.mp4' | relative_url }}" type="video/mp4">
    </video>
    <video autoplay muted loop width="100%">
      <source src="{{ '/assets/portfolio/impact/locomotion/teleport.mp4' | relative_url }}" type="video/mp4">
    </video>
  </div>
</div>

The movement calculation for the `Journey`, is handled by the `KinematicInterpolator`. The entire path that the player will travel is known beforehand and every `Motion` has its own maximum speed, acceleration and deceleration. The `KinematicInterpolator` calculates how long the player should accelerate and decelerate, to go as fast as possible while respecting all the settings. For example, if the next `Motion` has a lower maximum speed than the current one, the player will start decelerating before the transition so they arrive at exactly the right speed.

The feedback, such as sound effects and haptic effects, is also scheduled beforehand. A lot can happen in a short amount of time, while executing a journey. To not overwhelm the player, the `JourneyFeedbackComponent` curates what feedback will play. While constructing the `FeedbackQueue`, any added feedback is stored with a start time and a priority. If too much feedback would end up playing close together, then lower priority feedback is removed from the queue.

### Architecture

The core of the locomotion system is the `LocomotionMovementComponent`. This component aggregates movement transformations from various sources and then executes them all at once to improve performance.  
The `LocomotionMovementComponent` never decides to move on its own though. For that we have the `MovementController` components. Each component handles a different type of movement. The system is designed in a way where the `MovementControllers` do not reference each other, in order to make the system composable and to reduce coupling.  
We do however need to prevent conflicts between the controllers. For example, you should not be able to use stick movement while a `Journey` is executing. Preventing these conflicts is the job of the `LocomotionSupervisor`. `MovementControllers` can attempt to 'start' `GameplayTag` on the `LocomotionSupervisor`. Based on configured rules, starting a tag can interrupt another tag, while running tags can block other tags from starting. This allows us to prioritize certain movements over others, without requiring the `MovementControllers` to reference each other.

<img src="/assets/portfolio/impact/locomotion/locomotion-architecture-light.svg" width="100%">

### Accessibility

Accessibility and comfort were very important for this game, as we wanted anyone to be able to play the game. Even if they hadn't earner their 'VR legs' yet and were more prone to motion sickness. That's why the teleport locomotion mode was so important for us. But that's just the tip of the iceberg, when it comes to accessibility and comfort:  
- All `Journey` types can individually be configured to be instant or not. With the instant option the screen quickly fades to black, after which the journey executes in one tick, followed by the screen fading back in.
- For stick rotation, you can choose between 4 options. The 'Continuous' mode simply rotates you as you push your stick to the side, with a configurable speed. The 'Dash' mode quickly rotates you between fixed configurable angle increments. The 'Blink' mode works the same as the 'Dash' mode, but fades the screen in and out to perform the rotation instantly. The last option is to disable stick rotation entirely.
- A vignette is applied on the screen whenever the player moves or rotates, as this reduces motion sickness. There are also accessibility options to turn these vignettes off individually.
- I developed a physical climbing system for ladders, allowing you to climb up or down by grabbing the rungs of the ladder. I also added an accessibility option, allowing you to automatically climb up or down the ladder with a 'Journey', for which you can also choose whether you want it to be instant or not. In the teleport mode you can automatically climb ladder by aiming at it with the teleport targeting, and with the stick movement mode you simply need to walk into the ladder to trigger it.

Besides accessibility options, we kept comfort in mind for every aspect of the locomotion system. You can see that in the path the journeys take. We could have made jumps follow an arc, but we purposefully chose to move the player in a straight line as this is more comfortable.

{% endcapture_markdown %}

{% include card.html title="Locomotion" image="/assets/portfolio/impact/locomotion/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=locomotion %}





{% capture_markdown foot_ik %}

We were running into an issue, where the character's feet would clip with the ground while running up a slope or staircase. The reason was that the height of the feet was offset based on a downwards trace from the foot. This height needed to be interpolated, to prevent sudden pops on ledges and staircases. This did however mean that, when the feet were supposed to be planted on the ground, they would actually clip with the ground and still be interpolating upwards.

To solve this, I determined the slope angle using the NavMesh. I took the NavMesh polygons within a certain radius of the character and then calculated their average normal weighted by their area within the circle.

{% highlight C++ %}
FVector UVGSlopeDetectionComponent::GetAverageNormal(const ARecastNavMesh* NavMesh, const FVector& NavLocation, const TArray<NavNodeRef>& Polys) const
{
	FVector Normal = FVector::ZeroVector;
	TArray<FVector> Verts;
	for (const NavNodeRef Poly : Polys)
	{
		if (NavMesh->GetPolyVerts(Poly, Verts))
		{
			// Calculate the normal between multiple vertices, to prevent issues with perpendicular vertices
			FVector PolyNormal = FVector::ZeroVector;
			for (int32 i = 2; i < Verts.Num(); i++)
			{
				PolyNormal += FVector::CrossProduct(Verts[i] - Verts[0], Verts[i-1] - Verts[0]);
			}

			if (PolyNormal.SizeSquared() >= UE_THRESH_ZERO_NORM_SQUARED)
			{
				// Determine the Area within the Radius
				TArray<FVector2D> Verts2D;
				Verts2D.Reserve(Verts.Num());
				for (FVector Vert : Verts)
				{
					Verts2D.Add(FVector2D(Vert));
				}
				const float Area = UVGMathLibrary::CirclePolygonOverlapArea(FVector2D(NavLocation), Radius, Verts2D);

				Normal += Area * PolyNormal.GetUnsafeNormal();
			}
		}
	}
	return Normal.GetSafeNormal(UE_SMALL_NUMBER, FVector::UpVector);
}
{% endhighlight %}

Based on the slope angle and the traced ground height for each foot, I could determine a ground plane estimate for each foot. I was now able to interpolate the plane, instead of interpolating the ground height. As the foot was moving along the slope, it would keep finding the same plane and thus it wouldn't lag behind like it used to, fixing the clipping.  
As our NavMesh was static, I was also able to cache and reuse the calculated slope, as long as the character was close to the previous cached location.

<div style="container-type: inline-size">
  <div class="video-grid__responsive">
    <div style="width: 100%; text-align: center;">
      <video autoplay muted loop width="100%">
        <source src="{{ '/assets/portfolio/impact/foot-ik/before.mp4' | relative_url }}" type="video/mp4">
      </video>
      <em>Before</em>
    </div>
    <div style="width: 100%; text-align: center;">
      <video autoplay muted loop width="100%">
        <source src="{{ '/assets/portfolio/impact/foot-ik/after-debug.mp4' | relative_url }}" type="video/mp4">
      </video>
      <em>After</em>
    </div>
  </div>
</div>

I implemented the slope detection in a component and implemented the rest of the logic in control rig. This made it easy to test the system by dragging the ground planes around, allowing me to more easily iterate on things like the pelvis height and the pole vectors.
Another advantage of doing all the logic in control rig, was that I could skip the ground traces if the foot was already planted on the floor. This fixed a bug where feet could jitter up and down when the trace graced a ledge, while also saving us some performance for characters that were standing still.

<video autoplay loop muted controls width="100%" onloadstart="this.playbackRate = 2.0;">
  <source src="/assets/portfolio/impact/foot-ik/foot-ik.mp4" type="video/mp4">
</video>

{% endcapture_markdown %}

{% include card.html title="Foot IK in Control Rig" image="/assets/portfolio/impact/foot-ik/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=foot_ik %}





{% capture_markdown performance_optimization %}

Among other platforms, Metro Awaking released on Quest 2. The Quest 2's hardware is comparable to a high end smartphone at the time. With that hardware, it needs to render the game twice (once per eye), perform inside-out tracking and run the game logic itself. Needles to say, hitting our target fps on this platform was a super demanding challenge.

Besides the hardware limitations, VR also brings the necessity for a stable fps as that's super important to prevent motion sickness and for general comfort. For VR, you ideally want a stable 90 fps. This simply isn't possible on Quest 2, for a game like Metro. Hitting a native 60 fps also wasn't possible. Instead, we ran the game at 36 fps and used frame generation (Application SpaceWarp) to up that to 72 fps.

Even hitting that 36 fps target was a major challenge. We spend months focussing on just performance optimization. During that time, I got to intimately familiarize myself with performance profiling tools like [Unreal Insights](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-insights-in-unreal-engine) and fps charts. Our in-house 'Test Automation Framework' allowed us to automatically run repeatable level playthroughs, on the target hardware, making it easy to test and compare our performance improvements.

### Collision Optimization

Our asset artists were using a workflow where they used a lot of convex colliders in their assets, instead of more performant primitive colliders like boxes, spheres and capsules. This was especially problematic for cases where ragdolls were falling onto these expensive colliders.  
A lot of these convex colliders were actually shaped like boxes. The artists had created boxes in their 3d modeling software, but imported them into Unreal as convex colliders.  
They had done this, because boxes can be a bit finicky when meshes are scaled. When a box is rotated relative to its mesh, you'd intuitively expect that non-uniformly scaling said mesh would warp the box a bit. However, the physics system can't allow this, as boxes need to maintain their perfectly square corners. The way Unreal solves this problem, is to simply scale the boxes along their local axes instead. This can lead to some unexpected results.

<div style="display: flex">
  <div style="padding:5px">
    <img src="/assets/portfolio/impact/performance-optimization/collision-optimization/collision-scaling-text-before.png" width="100%">
  </div>
  <div style="padding:5px">
    <img src="/assets/portfolio/impact/performance-optimization/collision-optimization/collision-scaling-text-after.png" width="100%">
  </div>
</div>

*The colliders on the left are rotated, while those on the right are not. For each row, the planks are scaled along different axes.*

The 'trick' the artists used here, was to replace all boxes with convex colliders, which can be warped by non-uniform scaling. This did however have a significant performance impact.  
It was also unnecessary to do this everywhere, as most of our assets were never scaled anyway. And if they were, they could usually be made with non-rotated boxes which do work as expected.

I informed the asset team and updated our documentation. However, at the time we already had thousands of assets which were set up in this way. Fixing this manually would have been an enormous task.  
Instead, I created a simple tool (Asset Action Utility) which automatically converts 'box shaped' convex colliders to actual box colliders. Running this tool allowed me to easily fix 11363 assets in one go. This resulted in a 16% improvement in our average physics thread performance, and a 32% improvement in high load scenarios.

<div style="display: flex">
  <div style="padding:5px">
    <img src="/assets/portfolio/impact/performance-optimization/collision-optimization/tunnel-collision-before.png" width="100%">
    <img src="/assets/portfolio/impact/performance-optimization/collision-optimization/physics-performance-before.png" width="100%">
  </div>
  <div style="padding:5px">
    <img src="/assets/portfolio/impact/performance-optimization/collision-optimization/tunnel-collision-after.png" width="100%">
    <img src="/assets/portfolio/impact/performance-optimization/collision-optimization/physics-performance-after.png" width="100%">
  </div>
</div>

{% highlight C++ %}
bool UVGEditorAssetUtilities::TryConvertConvexToBox(const FKConvexElem& ConvexElement,
    const float Tolerance, UE::Geometry::FOrientedBox3d& OutBox)
{	
    // Boxes have 8 vertices. Sometimes convex elements have vertices which aren't in use.
    if (ConvexElement.VertexData.Num() < 8)
    {
        return false;
    }
    TSet Indices(ConvexElement.IndexData);
    if (Indices.Num() != 8)
    {
        return false;
    }

    // Apply the transformation of the convex element to the vertices (which are in use)
    TArray<FVector> Vertices;
    Vertices.Reserve(Indices.Num());
    for (const int32 Index : Indices)
    {
        Vertices.Add(ConvexElement.GetTransform().TransformPosition(ConvexElement.VertexData[Index]));
    }

    // This lambda checks if the given vertex is actually a corner of the box (within a tolerance)
    const float ToleranceSq = FMath::Square(Tolerance);
    const auto BoxIsWithinTolerance = [&Vertices, &ToleranceSq](const UE::Geometry::FOrientedBox3d& Box)
    {
        return Box.TestCorners([&Vertices, &ToleranceSq](const FVector& Corner)
        {
            return Vertices.ContainsByPredicate([&Corner, &ToleranceSq](const FVector& Vertex)
            {
                return FVector::DistSquared(Corner, Vertex) <= ToleranceSq;
            });
        });
    };

    // Try creating an AABB and check if all the vertices are box corners.
    // We try this first, as non-rotated boxes can be scaled properly, while rotated ones can't
    OutBox = UE::Geometry::FAxisAlignedBox3d(Vertices);
    if (BoxIsWithinTolerance(OutBox))
    {
        return true;
    }

    // Try creating an OBB and check if all the vertices are box corners.
    UE::Geometry::FMinVolumeBox3d MinVolumeBox;
    MinVolumeBox.Solve(Vertices.Num(), [&](const int32 Index) { return Vertices[Index]; });
    if (MinVolumeBox.IsSolutionAvailable())
    {
        MinVolumeBox.GetResult(OutBox);
        if (BoxIsWithinTolerance(OutBox))
        {
            return true;
        }
    }
    return false;
}
{% endhighlight %}

While this was a great performance improvement, it didn't catch the worst offenders as their colliders weren't box shaped. So I also wrote another tool which counted the number of convex collision elements and triangles, for each of our assets. This allowed me to find some really unoptimized assets, like a rail asset with 828 convex colliders, totalling 11040 convex triangles.
I also automatically determined the reference count for each asset. This created an easily prioritizable list, which I handed to the asset team. They went down the list, and manually optimized those assets. This improvement our physics performance further, by 15%.

Since our version control submit workflow was in the engine, I was also able to add a pre-submit check which warned people if they were about to submit an asset with colliders which could be optimized to boxes.

### Container Heap Allocation Optimization

While profiling the game, we were seeing random lag spikes which seemed to happen when we were allocating memory on the heap. We suspected that this was due to some kind of heap fragmentation issue, so we decided to try and reduce the number of heap allocations we do.  
I wanted to track down heap allocations, but Unreal's Memory Insights tool was still pretty limited at the time, especial on Quest 2. Instead, I added a cycle counter to `TSizedHeapAllocator` to count the number of heap allocations for all Unreal container types. This did require some hackery to prevent infinite loops, as the stats system also used these container types. I obviously never submitted this code, but it served it's purpose to identify 5 functions which were causing 49% of all container heap allocations.

By far the worst offender was `FHittestGrid`, from the engine's `SlateCore` module. This class singlehandedly contributed 34% of the container heap allocations.  
The grid was storing a bunch of cells, each of which contained a heap allocated array of widget indices. Each frame `FHittestGrid::ClearInternal` was being called, which deleted all those cells and thus released all those heap allocations. After that the cells would be re-added and the containers were reallocated.  

The way I fixed this, was to prevent the cells from being destroyed. Instead, I added a simple reset function for `FCell`, which reset its `WidgetIndexes` array while maintaining its heap allocation.

{% highlight Diff %}
+void FHittestGrid::FCell::Reset()
+{
+	WidgetIndexes.Reset();
+}

...

void FHittestGrid::ClearInternal(int32 TotalCells)
{
#if UE_SLATE_ENABLE_HITTEST_STATS
    SCOPE_CYCLE_COUNTER(STAT_SlateHTG_Clear);
#endif
-	Cells.Reset(TotalCells);
+	const int32 OldCellCount = Cells.Num();
    Cells.SetNumZeroed(TotalCells);
+	for (int32 i = 0; i < FMath::Min(OldCellCount, Cells.Num()); i++)
+	{
+		Cells[i].Reset();
+	}

    WidgetMap.Reset();
    WidgetArray.Reset();
    AppendedGridArray.Reset();
}
{% endhighlight %}

This simple change eliminated practically all the container allocations which were happening here, and thus reduced the total number of container allocations by 34%.

I only made this change, as we were in a late stage of the project and I knew that we wouldn't be switching engine versions anymore. Otherwise this would have been a very risky change, as future Unreal Engine versions might add a variable to `FCell`, which then wouldn't be reset by my `Reset` function. It would be a disaster waiting to happen.

An equivalent fix was implemented in a later version of Unreal Engine.

### Overlap event Optimization

When you create a `PrimitiveComponent` (`StaticMesh`, `Box/SphereCollision`, etc.), it will by default have the `Generate overlap events` toggle enabled. While the [overlap event](https://dev.epicgames.com/documentation/unreal-engine/collision-in-unreal-engine---overview#overlapandgenerateoverlapevents) feature is very useful to implement things like triggers, having the toggle enabled does impact performance. Every time the component moves it needs to perform a relatively expensive scene overlap query, in order to update what other components it's now overlapping with.  
While looking into the performance of Metro Awakening, I noticed that a lot of our game thread time was spent on updating these overlaps.

Some cases were simple to fix, as the overlap events were never used and I could simply disable the `Generate overlap events` toggle.
There were also some cases where triggers could be merged, like the 'gas mask equip trigger' and the 'hazard detection trigger' that were basically equivalent to the 'head trigger'.  
Other cases were less straightforward.

A large part of the overlap events were due to the hand interaction system. We had a triggerbox on the hand, which we used to detect interactable objects. This was very inefficient, as we were doing way more overlap queries than was necessary. Since Metro Awakening is a VR game, the hands will always move at least a tiny bit every frame. That also means that we're generating overlap events every frame. Meanwhile, we also had inventory sockets and interactable objects, like weapons, which were also generating overlap events every time they moved. And they were often also moving every frame, as the inventory slots were attached to the player and the interactable objects were often moving with physics or carried by the player or enemies.  
All these components were doing overlap queries almost every frame (and sometimes multiple times per frame), just so that we'd know if they're in front of a hand.  
To improve the performance, I disabled the overlap events on all these components. Instead, I simply performed a single overlap query per hand from the hand interaction tick. Another advantage of this approach was that I could also skip the overlap query altogether, if the hand was already holding something.

I was also able to optimize some of our triggers. We, for example, had a trigger on each weapon to detect magazines for insertion into the magazine chamber. These were doing overlap checks every time any weapon moved. I disabled this and performed a `ComponentOverlapComponent` query instead. I didn't need to do a full scene query, since I was only interested in the magazine the player was holding anyway. The query also ran less often, as the tick was only active if the weapon was held by a player. I was also able to save performance by performing cheaper checks first, like checking if the player was holding a compatible magazine and if the magazine chamber was empty.

These changes reduced the total number of overlap queries by 71%, which resulted in an overall performance improvement of 11% for our average game thread time.

<div style="display: flex">
  <div style="padding:5px">
    <img src="/assets/portfolio/impact/performance-optimization/overlap-event-optimization/performance-before.png" width="100%">
    <img src="/assets/portfolio/impact/performance-optimization/overlap-event-optimization/insights-before.png" width="100%">
  </div>
  <div style="padding:5px">
    <img src="/assets/portfolio/impact/performance-optimization/overlap-event-optimization/performance-after.png" width="100%">
    <img src="/assets/portfolio/impact/performance-optimization/overlap-event-optimization/insights-after.png" width="100%">
  </div>
</div>

This doesn't mean that you should never use overlap events. It definitely has it's place for static triggers.  
However, when both of the colliders are moving, you might want to consider doing a manual collision check. Especially if you already know the exact collider you want to check for. A `ComponentOverlapComponent` call is much more performant than using a `IsOverlappingComponent` call with overlap events enabled.  
Definitely do make sure to always disable the `Generate overlap events` toggle, if you're not using the overlaps anyway.

I do want to note that, as of writing this, `ComponentOverlapComponent` can give unexpected results. Welded bodies are included in overlap queries for the parent component, and not for the child component, which is different from how overlap events behave. The function also doesn't work for components with multiple bodies, like skeletal meshes. This is why I wrote a custom `ComponentOverlapComponent` function, which does handle these cases correctly.

{% endcapture_markdown %}

{% include card.html title="Performance Optimization" image="/assets/portfolio/impact/performance-optimization/teaser.png" excerpt="Among other platforms, Metro Awaking released on Quest 2. The Quest 2's hardware is comparable to a high end smartphone at the time. With that hardware, it needs to render the game twice (once per eye), perform inside-out tracking and run the game logic itself. Needles to say, hitting our target fps on this platform was a super demanding challenge. We spend months focussing on just performance optimization. During that time, I got to intimately familiarize myself with performance profiling tools like Unreal Insights and fps charts." collapsed_content=performance_optimization %}

[INDIGO - Creating the Illusion of Tactility in Metro Awakening VR](https://youtu.be/oslW2NthbTQ?si=rYYMAZ98zB9YXV5y)  
[GDC - 'Metro: Awakening': Development Postmortem](https://gdcvault.com/play/1035913/-Metro-Awakening-Development)