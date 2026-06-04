---
title: Unannounced Project
classes: wide centered
header:
  image: /assets/portfolio/unbound/hero.png
card:
  image: /assets/portfolio/unbound/teaser.png
  title: Unannounced Project
  from: Nov. 2024
  to: Jan. 2026
  excerpt: For an unannounced VR action adventure game based on a AAA IP, I created an expansive locomotion system featuring running, jumping, sliding, climbing, swimming and more.
  tags:
  - Unreal Engine 5
  - C++
  - Vertigo Games
---

For an unannounced VR action adventure game based on a AAA IP, I was responsible for one of the three gameplay pillars: Unbound Athlete. The goal was for players to experience a great sense of freedom as they used their (virtual) athletic skills to get to places where others couldn't go. Players needed to be able to jump across a chasm and grab a ledge at the last moment, climb along a steep wall and dive into the water from a 30 meter cliff.  
The sense of freedom was key. If it looked like the player could go somewhere, then it needed to be possible to do so.

With these grand aspirations, came an extensive list of requirements. The player needed to be able to walk, run, crouch, jump, fall, dodge, slide, climb, mantle, zipline, swing on ropes, swim and wade. And all of this with the added complication of VR, where the player is able to physically move around as well.
This was a massive technical undertaking that I owned end-to-end. Beyond the engineering work, I also played a key role in shaping the design itself, collaborating closely with a principal game designer ([Ruben Runhardt](https://rubenrunhardt.com/)) and the game director ([Kent Kune](http://www.kentyman.net/)) to ensure the system felt intuitive and satisfying.

Since our movement system needed to be so varied and custom, I decided to use [Unreal's Mover system](https://dev.epicgames.com/documentation/en-us/unreal-engine/mover-in-unreal-engine) as a base. Its architecture makes it easy to create independent movement modes, which lent itself perfectly to this project. Mover also has support for Trajectory Generation, which we needed for the [Motion Matching](https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-matching-in-unreal-engine) animation approach we were taking for our player character.

<div style="container-type: inline-size">
    <div class="video-grid__responsive">
        <video autoplay muted loop width="100%">
            <source src="/assets/portfolio/unbound/platforming-optimized.mp4" type="video/mp4">
        </video>
        <video autoplay muted loop width="100%">
            <source src="/assets/portfolio/unbound/sliding-optimized.mp4" type="video/mp4">
        </video>
        <video autoplay muted loop width="100%">
            <source src="/assets/portfolio/unbound/climbing-optimized.mp4" type="video/mp4">
        </video>
        <video autoplay muted loop width="100%">
            <source src="/assets/portfolio/unbound/swimming-optimized.mp4" type="video/mp4">
        </video>
    </div>
</div>

{% capture_markdown camera_movement %}

The best way to guarantee stability between the movement of the camera (VR headset) and the player character, was for the locomotion system to take full control of the camera movement. The system interfaced directly with OpenXR to retrieve information about the VR headset's position and rotation, along with additional information like 'tracking space recenter' calls.  
This information was gathered into a `FMoverInputCmdContext`, along with button and stick inputs, and passed to the movement modes. This allowed me to apply the camera movement differently, based on the movement mode:

- **Walking Mode**  
  The walking mode applied the horizontal headset movement as additional horizontal movement input. It was treated like regular movement input and could also be blocked by world geometry. This also prevented the player from moving the camera into world geometry.  
  Since the camera never actually moved relative to the player capsule, it was always centered on the player capsule.  
  The vertical headset movement was applied as crouching input, growing or shrinking the player capsule. This was also blocked by world geometry, preventing the camera from clipping through low ceilings.
- **Swimming Mode**  
  The swimming mode applied the full 3D headset movement as additional movement input. It was again treated like regular movement input and could also be blocked by world geometry.  
  The player capsule would remain at a fixed predetermined height.
- **Pause Mode**  
  While the game was paused, the player capsule was frozen in place. The headset movement was applied to the camera directly, allowing it to move away from the player capsule.  
  When the player unpaused, their camera would snap back to where they were before pausing.  
  This approach ensured that the player could not cheat certain gameplay challenges by using the pause menu, while preventing motion sickness by ensuring that the player view would still move with their head.

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/camera-movement/pause-menu.mp4" type="video/mp4">
</video>

### Crouching
The crouching system was inspired by [BONELAB](https://store.steampowered.com/app/1592190/BONELAB/). The player had to move their joystick up or down to stand or crouch respectively, instead of pressing the joystick to toggle the state.  
One advantage of this approach was that it paired nicely with the swimming mode, which used the same up/down stick input to allow the player to swim up or down.  
Another advantage was that holding the stick down longer would allow us to trigger a crawling mode in the future, which we were considering.  
More importantly though, this control scheme allowed us to drop the notion of explicitly being in a 'standing' or 'crouching' state. This is a logical fit for a VR game, as the player can physically move up or down to any height as well.

Moving the joystick up or down would interpolate the camera to a predetermined 'standing' or 'crouching' height. This was the same for players of all sizes, to ensure everyone would be able to reach the same ledges and would be able to fit into the same crouching areas.  
This also meant that any up/down input would also server as a quick height calibration.  
Beyond that, the player was able to freely move their head up or down, although clamped within some constraints to prevent cheating and clipping through the ground.

Based on the camera's actually height, I determined whether the player was 'crouching'. This information was used to alter things like the movement speed, animations, footstep sounds and the noise detection radius for AI characters.

### Height Correction

Ideally, the player should always be at either the standing or crouching height, as the levels are designed with those metrics in mind. A tall player might want to physically crouch, but might not get low enough to actually fit into our crouching areas. That's why I implemented a height correction system, which smoothly moves the camera back to our desired heights. An important requirement was for the effect to be subtle, so that players wouldn't notice it.

If the player was standing still, they'd notice if their camera was being moved up or down over time. That's why I moved the camera based on the speed of the horizontal locomotion movement. The quicker they'd move the faster the height correction would be, as it would also be less noticeable. No height correction would happen if they were standing still.

It would also be noticeable if the height correction would move you too far. That's why I would only apply the height correction if the camera was within 20cm of either the standing or the crouching height.

The height correction shouldn't be applied when a player is actively moving their head up and down, as this would disrupt the movement parity between their head and their view, which would be uncomfortable and lead to motion sickness. To prevent this, I simply check if the player is moving their head up or down faster than a generously small threshold of 10cm/s.

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/camera-movement/height-correction-with-text-cropped.mp4" type="video/mp4">
</video>

A problem I ran into was that, due to human anatomy, pitching you head up or down would also move the headset up or down. The height correction system was adjusting for this, which felt unnatural.  
To fix this, I measured how the headset moved as different people pitched their head up and down. From this data I was able to construct a curve which maps the headset's pitch to an offset which estimates where the headset would have been without pitch. I was then able to use this offset to get a better estimate of the camera height, to eliminate the issue I described earlier.  
As an added bonus, I was also able to use this offset in other scenarios. If your height is being clamped, for example, you'll still be able to pitch your head without the clamping affecting that movement.

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/camera-movement/height-prediction-cropped.mp4" type="video/mp4">
</video>

![](/assets/portfolio/unbound/camera-movement/pitch-to-camera-offset.png)

{% endcapture_markdown %}

{% include card.html title="Camera Movement" image="/assets/portfolio/unbound/camera-movement/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=camera_movement %}





{% capture_markdown camera_smoothing %}

Comfort and motion sickness are important considerations for any VR game. Having the camera jitter up and down, as you're walking on uneven ground (especially stairs), leads to an uncomfortable game experience.  
For precisely this reason, our locomotion system from [Metro Awakening](#metro-awakening) used the [NavMesh](https://dev.epicgames.com/documentation/en-us/unreal-engine/navigation-system-in-unreal-engine) as a reliably flat surface for the player to walk on. With the movement freedom required for this game however, we could no longer rely on the NavMesh being able to generate on every surface on which the player might find themselves. This locomotion system needed to be collision based, but ground collision is not smooth.  
Relying on level designers to manually place invisible colliders was not an option, as this would have been too much work, unreliable and hard to maintain and test. We needed an automated system which could reliable handle any situation.

Having a smooth camera was so important for us, that it was one of the first things I prototyped before starting on implementing the full system itself.  
My solution consisted of two steps:

1. To know how to smoothen the camera movement, I needed an estimate of the ground plane.  
The naive approach would have been to perform a bunch of traces around the player, to get sample points to estimate the ground plane. However, I decided to use the [Motion Matching](https://dev.epicgames.com/documentation/en-us/unreal-engine/motion-matching-in-unreal-engine) trajectory instead, as we were already generating that for the animation system anyway. This way the ground plane estimate was very cheap to compute. Another advantage is that we only look at actually relevant ground collision: where we were and where we're going.  
I wrote an algorithm which takes all the trajectory points, filters them and uses them to calculate a weighted average up-vector for the ground plane estimate.
2. While the player was walking around, any height changes would be ignored by the camera. Then, after all the movement was performed, a camera smoothing step was responsible for moving the camera back into alignment. Based on the ground plane estimate that was computed earlier, I could calculate where we estimate the player character to be in 2 meters. For this location, there was also a desired camera location. Then, it was as simple as moving the camera along the line between the previous camera location and the desired camera location. If the ground angle didn't change, the camera would be realigned after 2 meters.

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/camera-smoothing/visual-log-cropped.mp4" type="video/mp4">
</video>

*The desired camera height (purple line) is drawn based on the 'ground plane estimate' (magenta circle). The camera is moved along the yellow line, so that it'll be at the desired height after 2 meters.*

The beauty of this system is that it doesn't just respond to height changes, it anticipates them. The ground plane estimate will detect if we're transitioning from flat ground to an incline. This means that the desired camera location will have moved up, and that we'll start moving the camera up already. The camera won't move due to the step-up, so it will go from being a bit too high to being a bit too low. This makes step-ups/downs feel smoother, as we minimize the height difference between the actual and desired camera height.  
Another advantage of this system is that it's stable when walking along a longer slope. Once the camera is realigned at the desired height, the '2 meter long line we move the camera along' will be parallel with the ground. This means that the camera will stably remain at the desired height, as if the smoothing wasn't even there.

<div style="container-type: inline-size">
    <div class="video-grid__responsive">
        <video autoplay muted loop width="100%">
            <source src="/assets/portfolio/unbound/camera-smoothing/disabled.mp4" type="video/mp4">
        </video>
        <video autoplay muted loop width="100%">
            <source src="/assets/portfolio/unbound/camera-smoothing/enabled.mp4" type="video/mp4">
        </video>
    </div>
</div>

{% endcapture_markdown %}

{% include card.html title="Camera Smoothing" image="/assets/portfolio/unbound/camera-smoothing/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=camera_smoothing %}





{% capture_markdown climbing %}

In the climbing mode, I simply apply the player's controller movement to the body, in the opposite direction. This causes the controller to realign with the visual hand and moves you in the way you'd expect.  
However, the player capsule's movement can be obstructed by level geometry, causing the controller to not align with the hand anymore. I solve this by not applying any controller movement which brings the controller closer to the visual hand. This way the hand parity is restored, before the player moves again. The hand automatically releases if the distance between the controller and visual hand becomes large, causing the player too fall.  

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/climbing/obstructed-by-level-geometry.mp4" type="video/mp4">
</video>

While climbing, only 1 'active' hand is actually followed. This is always the last hand that grabbed a climbing hold. The other hand will still visually hold on, but the movement isn't actually being followed. This might sound strange, but it's actually the most intuitive. For most players their focus is on what they grabbed last, so they expect their body to follow that hand. Players also tend to intuitively move both hands in sync, preventing hand parity loss.  
If the player releases their active hand, then their other hand becomes the active hand. When this happens, the controller isn't aligned with the visual hand anymore. To fix this, I simply interpolate the body to resolve this offset. This quickly and smoothly realigns the controller and visual hand. The interpolation is also relevant when a player initially grabs a hold, as the body needs to move slightly due to the hand moving to grab the climbing hold.   

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/climbing/interpolation-to-resolve-hand-parity.mp4" type="video/mp4">
</video>

{% highlight C++ %}
// Determine the controller movement
const FTransform TrackingOriginTransform = XRState.TrackingOriginTransform * DefaultState.GetTransform_WorldSpace();
const FVector OldControllerLocation = TrackingOriginTransform.TransformPosition(ActiveGrab->StatePose.Location);
const FTransform NewControllerTransform = FTransform(ActiveGrab->InputPose) * TrackingOriginTransform;
FVector ControllerMovement = NewControllerTransform.GetLocation() - OldControllerLocation;

// Remove the movement which brings the controller back to the alignment point.
const FVector ControllerAlignmentPoint = NewControllerTransform.TransformPosition(
    ActiveGrab->ClimbingState.ControllerAlignmentPoint);
const FVector AttachAlignmentPoint = ActiveGrab->ClimbingState.GetWorldAttachAlignmentPoint();
const FVector AlignmentVector = AttachAlignmentPoint - ControllerAlignmentPoint;
const FVector AlignmentMovement = UVGMathLibrary::ClampedProjectOnToVector(ControllerMovement, AlignmentVector);
ControllerMovement -= AlignmentMovement;

// The body moves in the opposite direction of the controller. This way the hand remains in place.
BodyMovement = -ControllerMovement;

// Interpolate the controller to the alignment point.
if (ClimbingSettings->ControllerAlignmentInterpSpeed > 0)
{
    const FVector RemainingAlignmentMovement = AlignmentVector - AlignmentMovement;
    BodyMovement += FMath::VInterpTo(FVector::ZeroVector, RemainingAlignmentMovement, DeltaSeconds,
        ClimbingSettings->ControllerAlignmentInterpSpeed);
}
{% endhighlight %}

{% endcapture_markdown %}

{% include card.html title="Climbing" image="/assets/portfolio/unbound/climbing/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=climbing %}





{% capture_markdown mantling %}

I wanted the mantling system to be fully dynamic, requiring no setup from level designers. That's why I created a system to reliably find a mantling destination.

The moment the player releases both hands, I sweep the player's capsule, horizontally, in the direction of the camera. If this hits a wall, I store 2 locations a bit further into the wall. One location is moved further along the sweep direction, while the other is moved perpendicularly into the wall along the wall normal.  
I then sweep the player capsule again, using the wall normal to sweep perpendicularly into the wall. I again store a location, a bit further into the wall.  
Starting with the closest stored location, I try to find an unobstructed location with a walkable floor. I test various heights, from the player's current height up to floors at eye height.  
I then check if there is an unobstructed path to the found location, preferring a standing destination but also handling crouching for low ceilings.  
The player will simply fall if no valid destination is found.

This system has proven to be very reliable. It's also very intuitive for players, as they'll simply mantle where they're looking.  
The heights at which I check for mantle destinations also ensure that players will only mantle onto ledges below their eye height, giving them the option to drop down instead by simply moving themselves below the ledge.  
The height checks also ensure that players will never mantle downwards. Instead they can position themselves over the platform, dropping themselves onto it.

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/mantling/dynamic-mantling-cropped.mp4" type="video/mp4">
</video>

{% endcapture_markdown %}

{% include card.html title="Dynamic Mantling" image="/assets/portfolio/unbound/mantling/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=mantling %}





{% capture_markdown rope-swinging %}

### Pendulum Swinging

To keep the rope swinging reliable, I decided to always keep the rope in tension and to model it as a frictionless pendulum with the following formula:

$$\Delta \vec{\omega} = \frac{\vec{r} \times \vec{g}}{\Vert \vec{r} \Vert^{2}} \cdot \Delta t$$

Where:

- $$\Delta \vec{\omega}$$ is the change in angular velocity.
- $$\vec{r}$$ is the position vector from the pivot to the pendulum bob, in our case the player.
- $$\Vert \vec{r} \Vert$$ is the the length of the pendulum string.
- $$\vec{g}$$ is the gravitation acceleration vector.
- $$\Delta t$$ is the time step.

This simple formula results in a stable pendulum motion, as long as you add sub-stepping to prevent lag spikes or low fps from introducing instability.  
I also added some simple linear $$(c_l)$$ and quadratic $$(c_q)$$ drag:

$$\Delta \vec{\omega} = - (c_l \Vert \vec{\omega} \Vert + c_q \Vert \vec{\omega} \Vert^2) \cdot \Delta t$$

### Player Input

The next step was to give the player control. My first approach was to simply apply the stick input as additional angular velocity. This worked, but was hard to control as it was difficult to gauge your swinging direction and as the turning took a bit of time. This meant that people would overconnect and overshoot the direction they wanted to swing in.  
We also ran into a problem, which I called orbiting. Instead of swinging back and forth in a straight line, underneath the pivot, the player could end up in a situation where they would swing around in circles around the pivot. This situation was easy to get yourself into, extremely hard to get yourself out of, and nauseating.  
I tackled both these issues by reworking the player input. I only looked at the forwards and backwards stick input, in the direction of the camera. I would then rotate the `RopeRotation` and `AngularVelocity` over time, around the vertical center axis, to align with the direction the player was looking in. This was much more intuitive, as the player could simply look where they wanted to go.  
To accelerate, the player needed to move their joystick back and forth with the rhythm of the swing, mimicking the motion you'd make with your legs while on a swingset.

{% highlight C++ %}
const FVector2D RawStickInput = GetStickInput();
const FVector2D StickInput = RawStickInput.IsNearlyZero(StickInputTolerance)
    ? FVector2D::ZeroVector : FVector2D(RawStickInput.X, 0).GetRotated(GetCameraYaw());

// Rotate the AngularVelocity and RopeRotation around the vertical center axis
const float TargetRotationSpeed = [&]
{
    if (AngularVelocity.IsNearlyZero() && StickInput.IsZero())
    {
        return 0.f;
    }

    const FVector AngularStickInput = FVector(StickInput, 0).Cross(FVector::UpVector);
    const float AngleDifference = FMath::UnwindRadians(
        FMath::Atan2(AngularStickInput.Y, AngularStickInput.X)
        - FMath::Atan2(AngularVelocity.Y, AngularVelocity.X));

    // Flip backwards directions around by 180 degrees
    const float TargetDeltaAngle = AngleDifference > UE_HALF_PI || AngleDifference < -UE_HALF_PI
        ? FMath::UnwindRadians(AngleDifference + UE_PI) : AngleDifference;
    
    // Clamp the speed, such that it smoothly decelerates to 0 as we approach the target
    const float MaxRotationSpeed = FMath::Min(MaxStickRotationSpeed,
        FMath::Sqrt(FMath::Abs(2 * TargetDeltaAngle * StickRotationDeceleration)));
    return FMath::Clamp(TargetDeltaAngle, -MaxRotationSpeed, MaxRotationSpeed);
}();
const float InterpSpeed = FMath::Abs(StickRotationSpeed) < FMath::Abs(TargetRotationSpeed)
        ? StickRotationAcceleration : StickRotationDeceleration;
StickRotationSpeed = FMath::FInterpConstantTo(StickRotationSpeed,
    TargetRotationSpeed, DeltaSeconds, InterpSpeed);
const FQuat DeltaRotation(FVector::UpVector, StickRotationSpeed);
AngularVelocity = DeltaRotation.RotateVector(AngularVelocity);
RopeRotation = DeltaRotation * RopeRotation;

// Accelerate/Decelerate without changing the direction of the AngularVelocity
const FVector DeltaAngularVelocity = RopeRotation.Vector().Cross(
    FVector(StickInput * StickAcceleration, 0)) / GetPendulumLength() * DeltaSeconds;
AngularVelocity += AngularVelocity.IsNearlyZero()
    ? FVector(DeltaAngularVelocity.X, DeltaAngularVelocity.Y, 0)
    : DeltaAngularVelocity.ProjectOnTo(AngularVelocity);
{% endhighlight %}

The player could still get into an orbiting situation, if they jumped sideways onto a rope that was already swinging.  
During a regular non-orbiting swing, the `AngularAcceleration` vector is perpendicular to the plane defined by `RopeRotation` vector and the gravity vector. This isn't the case while orbiting. To blend out the orbiting, all I needed to do was to slowly rotate the `AngularAcceleration` to be perpendicular with that plane again.

<div style="container-type: inline-size">
    <div class="video-grid">
        <video autoplay muted loop width="100%">
            <source src="/assets/portfolio/unbound/rope-swinging/orbiting-before-cropped.mp4" type="video/mp4">
        </video>
        <video autoplay muted loop width="100%">
            <source src="/assets/portfolio/unbound/rope-swinging/orbiting-after-cropped.mp4" type="video/mp4">
        </video>
    </div>
</div>

### Swing Angle Clamping

I wanted to limit the maximum swinging angle, to make the mechanic reliable and to prevent unnaturally high swings. The naive approach would be to simply clamp the angle, but this has downside of introducing a clear hard barrier which you can hit. I wanted the swing to smoothly end up at exactly the maximum angle I configured. To do this, I needed to calculate the maximum angular speed at any angle such that the angular speed would be exactly 0 at my configured maximum angle. For this I was able to come up with the following formula.

{% capture_markdown swing_angle_clamping_formula %}
$$\Vert \vec{\omega} \Vert = \sqrt{\frac{2 \cdot \Vert \vec{g} \Vert \cdot (\cos(\theta) - \cos(\theta_{\text{max}}))}{\Vert \vec{r} \Vert \cdot \sin^2(\angle(\vec{\omega}, \vec{r}))}}$$
{% endcapture_markdown%}

{% capture_markdown swing_angle_clamping_derivation %}
We can calculate the maximum velocity by using conservation of energy. At the given angle $$(\theta_i)$$, the system will have some amount of potential energy $$(E_{p,i})$$ and kinetic energy $$(E_{k,i})$$. At the maximum angle $$(\theta_{\text{max}})$$, the system will have some amount of potential energy $$(E_{p,f})$$ but no kinetic energy.  
As energy is conserved:

$$E_{p,i} + E_{k,i} = E_{p,f}$$

Substitute $$E_p = m g h$$ and $$E_k = \frac{1}{2} m \Vert \vec{v} \Vert^2$$

$$m \Vert \vec{g} \Vert h_i + \frac{1}{2} m \Vert \vec{v}_i \Vert^2 = m \Vert \vec{g} \Vert h_f$$

Substitute $$h = \Vert r \Vert (1 - \cos(\theta))$$ and $$\vec{v} = \vec{\omega} \times \vec{r}$$

$$m \Vert \vec{g} \Vert \Vert r \Vert (1 - \cos(\theta_i)) + \frac{1}{2} m \Vert \vec{\omega} \times \vec{r} \Vert^2 = m \Vert \vec{g} \Vert \Vert r \Vert (1 - \cos(\theta_{\text{max}}))$$

Substitute $$\Vert \vec{a} \times \vec{b} \Vert = \Vert \vec{a} \Vert \Vert \vec{b} \Vert \sin(\angle(\vec{a} \times \vec{b}))$$

$$m \Vert \vec{g} \Vert \Vert r \Vert (1 - \cos(\theta_i)) + \frac{1}{2} m (\Vert \vec{\omega} \Vert \Vert \vec{r} \Vert \sin(\angle(\vec{\omega}, \vec{r})))^2 = m \Vert \vec{g} \Vert \Vert r \Vert (1 - \cos(\theta_{\text{max}}))$$

Solve for $$\Vert \vec{\omega} \Vert$$

$$\Vert \vec{g} \Vert \Vert r \Vert (1 - \cos(\theta_i)) + \frac{1}{2} (\Vert \vec{\omega} \Vert \Vert \vec{r} \Vert \sin(\angle(\vec{\omega}, \vec{r})))^2 = \Vert \vec{g} \Vert \Vert r \Vert (1 - \cos(\theta_{\text{max}}))$$

$$\frac{1}{2} (\Vert \vec{\omega} \Vert \Vert \vec{r} \Vert \sin(\angle(\vec{\omega}, \vec{r})))^2 = \Vert \vec{g} \Vert \Vert r \Vert (1 - \cos(\theta_{\text{max}})) - \Vert \vec{g} \Vert \Vert r \Vert (1 - \cos(\theta_i))$$

$$(\Vert \vec{\omega} \Vert \Vert \vec{r} \Vert \sin(\angle(\vec{\omega}, \vec{r})))^2 = 2 \Vert \vec{g} \Vert \Vert r \Vert ((1 - \cos(\theta_{\text{max}})) - (1 - \cos(\theta_i)))$$

$$\Vert \vec{\omega} \Vert^2 \Vert \vec{r} \Vert^2 \sin^2(\angle(\vec{\omega}, \vec{r})) = 2 \Vert \vec{g} \Vert \Vert r \Vert (\cos(\theta_i) - \cos(\theta_{\text{max}}))$$

$$\Vert \vec{\omega} \Vert^2 \Vert \vec{r} \Vert \sin^2(\angle(\vec{\omega}, \vec{r})) = 2 \Vert \vec{g} \Vert (\cos(\theta_i) - \cos(\theta_{\text{max}}))$$

$$\Vert \vec{\omega} \Vert^2 = \frac{2 \Vert \vec{g} \Vert (\cos(\theta_i) - \cos(\theta_{\text{max}}))}{\Vert \vec{r} \Vert \sin^2(\angle(\vec{\omega}, \vec{r}))}$$

$$\Vert \vec{\omega} \Vert = \sqrt{\frac{2 \Vert \vec{g} \Vert (\cos(\theta_i) - \cos(\theta_{\text{max}}))}{\Vert \vec{r} \Vert \sin^2(\angle(\vec{\omega}, \vec{r}))}}$$
{% endcapture_markdown%}

<div class="math-derivation">
    {% include card.html excerpt=swing_angle_clamping_formula collapsed_content=swing_angle_clamping_derivation %}
</div>

This formula does have one issue, in that it doesn't return a real result if $$\theta > \theta_{\text{max}}$$. Returning 0 instead makes sense, but does mean that the rope would get stuck if it ever got higher than the maximum angle. Which can happen due to floating point innacuaries and the discrete math. To solve this, I simply interpolated the `AngularVelocity` to this maximum angular speed instead. This meant the rope would never get fully stuck, but would in practice still be clamped to within a degree of the maximum swing angle.

{% endcapture_markdown %}

{% include card.html title="Rope Swinging" image="/assets/portfolio/unbound/rope-swinging/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=rope-swinging %}





{% capture_markdown swimming %}

We wanted the swimming mode to feel realistic, requiring the player to actually swing their arms to move themselves around. That's why I decided to model the entire system around drag. The player's body would experience water drag, slowing them down. But the hands would also experience drag as the player swung them around, speeding the player up.  
The formula for drag boils down to $$F = c \cdot v^2$$, where $$F$$ is the drag force, $$c$$ is an amalgamation of various constants and $$v$$ is the velocity difference between the object and the water. While this was physically accurate, it didn't feel good. The exponential nature of drag meant that the drag on the body felt too strong while you were moving quickly, but it also wasn't strong enough to bring you too a full stop. That's why I setup a system which allowed us to tweak constant, linear and quadratic drag separately. This gave us the tools to tweak the system to feel as floaty as you'd expect from swimming, while still giving you a sense of control. I used this simple formula:

$$v_f = v_i - \Delta t(c_q \cdot v_i^2 + c_l \cdot v_i + c_c)$$

I did run into an issue, in that the drag felt inconsistent due to the discrete calculation. This is because the deceleration was calculated for the full timestep $$t$$, as if we were moving with a velocity of $$v_i$$ for the full timestep. In reality, that deceleration would constantly lower $$v_i$$ and thus the deceleration would also be lower. The simple calculation thus resulted in a deceleration that was too high and inconsistent depending on frame rate.  
The solution was to use integration, to calculate the area under the velocity curve. This results in the following formula:

{% capture_markdown swimming_formula %}
$$v(t) = \frac{c_l \cdot v_0 \cdot e^{-c_lt}}{c_l + c_q \cdot v_0(1 - e^{-c_lt})} - c_c \cdot t$$
{% endcapture_markdown %}

{% capture_markdown swimming_derivation%}
We look at the velocity change $$(dv)$$ over an infinitesimally small time step $$(dt)$$.

$$\frac{dv}{dt} = -(c_q v^2 + c_l v)$$

$$\frac{dv}{dt} = -v(c_q v + c_l)$$

Integrate both sides from 0 to a desired time step t.

$$\int_{v_0}^{v_t} \frac{1}{v(c_q v + c_l)} dv = \int_0^t -dt$$

Solve using partial fraction decomposition.

$$\frac{1}{v(c_q v + c_l)} = \frac{A}{v} + \frac{B}{c_q v + c_l}$$

$$1 = A(c_q v + c_l) + Bv$$

If $$v = 0$$, then $$1 = A(c_l) + B \cdot 0 \implies A = 1/c_l$$  
If $$v = -c_l / c_q$$, then $$1 = A(0) + B(-c_l / c_q) \implies B = -c_q / c_l$$.

Substitute and integrate.

$$\int_{v_0}^{v_t} \frac{1/c_l}{v} + \frac{-c_q / c_l}{c_q v + c_l} dv = \int_0^t -dt$$

$$\frac{1}{c_l} \int_{v_0}^{v_t} \frac{1}{v} + \frac{-c_q}{c_q v + c_l} dv = \int_0^t -dt$$

$$\frac{1}{c_l} [\ln|v| - \ln|c_q v + c_l|]_{v_0}^{v_t} = -t$$

$$\frac{1}{c_l} \left[ \ln \left| \frac{v}{c_q v + c_l} \right| \right]_{v_0}^{v_t} = -t$$

$$\frac{1}{c_l} \left( \ln \left| \frac{v_t}{c_q v_t + c_l} \right| - \ln \left| \frac{v_0}{c_q v_0 + c_l} \right| \right) = -t$$

$$\ln \left| \frac{v_t(c_q v_0 + c_l)}{v_0(c_q v_t + c_l)} \right| = -c_l t$$

Solve for $$v_t$$ and simplify.

$$\frac{v_t(c_q v_0 + c_l)}{v_0(c_q v_t + c_l)} = e^{-c_l t}$$

$$v_t(c_q v_0 + c_l) = (c_q v_t + c_l) v_0 e^{-c_l t}$$

$$v_t(c_q v_0 + c_l) = c_q v_t v_0 e^{-c_l t} + c_l v_0 e^{-c_l t}$$

$$v_t(c_q v_0 + c_l) - c_q v_t v_0 e^{-c_l t} = c_l v_0 e^{-c_l t}$$

$$v_t(c_q v_0 + c_l - c_q v_0 e^{-c_l t}) = c_l v_0 e^{-c_l t}$$

$$v_t(c_l + c_q v_0 (1 - e^{-c_l t})) = c_l v_0 e^{-c_l t}$$

$$v_t = \frac{c_l v_0 e^{-c_l t}}{c_l + c_q v_0 (1 - e^{-c_l t})}$$
{% endcapture_markdown %}

<div class="math-derivation">
    {% include card.html excerpt=swimming_formula collapsed_content=swimming_derivation %}
</div>

The constant drag is tacked onto the formula and isn't included in the integration. This means the solution isn't 100% correct, but it was good enough to solve or problem without introducing unnecessary complexity. Including the constant drag in the integration complicates the math a lot.

{% highlight C++ %}
FVector UVGSwimmingUtils::ApplyDrag(const FVector& Velocity, const float Mass,
    const FVGSwimmingDragSettings& DragSettings, const float DeltaTime)
{
    const FVector::FReal Speed = Velocity.Size();
    if (DeltaTime <= 0 || Speed <= 0)
    {
        return Velocity;
    }
    
    const float LinearDrag = DragSettings.LinearDrag / Mass;
    const float QuadraticDrag = FMath::Max(DragSettings.QuadraticDrag / Mass, 0);

    FVector::FReal VelocityScale;
    if (LinearDrag <= 0)
    {
        // Only quadratic drag
        VelocityScale = 1 / (1 + QuadraticDrag * Speed * DeltaTime);
    }
    else
    {
        // Linear (and quadratic) drag
        const float ExpTerm = FMath::Exp(-LinearDrag * DeltaTime);
        VelocityScale = LinearDrag * ExpTerm / (LinearDrag + QuadraticDrag * Speed * (1.0 - ExpTerm));
    }

    // Apply the constant drag
    VelocityScale = FMath::Max(0, VelocityScale - DragSettings.ConstantDrag * DeltaTime / Speed);

    return Velocity * VelocityScale;
}
{% endhighlight %}

{% capture swimming_derivation_full_text %}
While writing this I figured I'd give the full derivation a shot, with the constant drag included in the integration. The math does work out, but unfortunately splits off into separate cases.
{% endcapture %}

{% capture_markdown swimming_derivation_full %}
We look at the velocity change $$(dv)$$ over an infinitesimally small time step $$(dt)$$.

$$\frac{dv}{dt} = -(c_q v^2 + c_l v + c_c)$$

Integrate both sides from 0 to a desired time step t.

$$\int_{v_0}^{v_t} \frac{1}{c_q v^2 + c_l v + c_c} dv = \int_0^t -dt$$

Completing the square.

$$c_q v^2 + c_l v + c_c$$

$$c_q \left( v^2 + \frac{c_l}{c_q}v \right) + c_c$$

$$c_q \left( v^2 + \frac{c_l}{c_q}v + \left( \frac{c_l}{2c_q} \right)^2 - \left( \frac{c_l}{2c_q} \right)^2 \right) + c_c$$

$$c_q \left( \left(v + \frac{c_l}{2c_q} \right)^2 - \left( \frac{c_l}{2c_q} \right)^2 \right) + c_c$$

$$c_q \left( \left(v + \frac{c_l}{2c_q} \right)^2 + \frac{c_c}{c_q} - \left( \frac{c_l}{2c_q} \right)^2 \right)$$

We now have an equation in the completed-square form: $$(v + h)^2 + k$$,  
where h = $$\frac{c_l}{2c_q}$$ and k = $$\frac{c_c}{c_q} - h^2$$.

$$\int_{v_0}^{v_t} \frac{1}{c_q((v + h)^2 + k)} dv = \int_0^t -dt$$

$$\frac{1}{c_q} \int_{v_0}^{v_t} \frac{1}{(v + h)^2 + k} dv = \int_0^t -dt$$

Case 1: $$k > 0$$.  
We use the standard form $$\int \frac{1}{u^2 + a^2} du = \frac{1}{a} \arctan(\frac{u}{a})$$.  
Let $$a^2 = k$$ and $$u = v + h$$.

$$\frac{1}{c_q} \int_{u_0}^{u_t} \frac{1}{u^2 + a^2} du = \int_0^t -dt$$

$$\frac{1}{c_q a} \left[ \arctan \left( \frac{u}{a} \right) \right]_{u_0}^{u_t} = -t$$

$$\arctan \left( \frac{u_t}{a} \right) - \arctan \left( \frac{u_0}{a} \right) = -c_q a t$$

$$\arctan \left( \frac{u_t}{a} \right) = \arctan \left( \frac{u_0}{a} \right) - c_q a t$$

$$\frac{u_t}{a} = \tan \left( \arctan \left( \frac{u_0}{a} \right) - c_q a t \right)$$

$$u_t = a \cdot \tan \left( \arctan \left( \frac{u_0}{a} \right) - c_q a t \right)$$

$$v_t = \sqrt{k} \cdot \tan \left( \arctan \left( \frac{v_0 + h}{\sqrt{k}} \right) - c_q \sqrt{k} t \right) - h$$

Case 2: $$k < 0$$  
We use the standard form $$\int \frac{1}{u^2 - a^2} du = -\frac{1}{a} \text{artanh}(\frac{u}{a})$$  
Let $$-a^2 = k$$ and $$u = v + h$$

$$\frac{1}{c_q} \int_{u_0}^{u_t} \frac{1}{u^2 - a^2} du = \int_0^t -dt$$

$$-\frac{1}{c_q a} \left[ \operatorname{artanh} \left( \frac{u}{a} \right) \right]_{u_0}^{u_t} = -t$$

$$\operatorname{artanh} \left( \frac{u_t}{a} \right) - \operatorname{artanh} \left( \frac{u_0}{a} \right) = c_q a t$$

$$\operatorname{artanh} \left( \frac{u_t}{a} \right) = \operatorname{artanh} \left( \frac{u_0}{a} \right) + c_q a t$$

$$\frac{u_t}{a} = \tanh \left( \operatorname{artanh} \left( \frac{u_0}{a} \right) + c_q a t \right)$$

$$u_t = a \cdot \tanh \left( \operatorname{artanh} \left( \frac{u_0}{a} \right) + c_q a t \right)$$

$$v_t = \sqrt{k} \cdot \tanh \left( \operatorname{artanh} \left( \frac{v_0 + h}{\sqrt{k}} \right) + c_q \sqrt{k} t \right) - h$$

Case 3: $$k = 0$$

$$\frac{1}{c_q} \int_{v_0}^{v_t} \frac{1}{(v + h)^2} dv = \int_0^t -dt$$

$$\frac{1}{c_q} \int_{u_0}^{u_t} \frac{1}{u^2} du = \int_0^t -dt$$

$$\frac{1}{c_q} \left[ -\frac{1}{u} \right]_{u_0}^{u_t} = -t$$

$$\frac{1}{u_t} - \frac{1}{u_0} = c_q t$$

$$u_t = \frac{1}{\frac{1}{u_0} + c_q t}$$

$$v_t = \frac{1}{\frac{1}{v_0 + h} + c_q t}$$
{% endcapture_markdown %}

<div class="math-derivation">
    {% include card.html excerpt=swimming_derivation_full_text collapsed_content=swimming_derivation_full %}
</div>

With the drag sorted, there was still the question of when and how to apply that drag from the hands. Having it always enabled wouldn't work, as you'd push yourself back and forth as you swing your arms back and forth.
I went through various iterations, to find satisfying controls.  
The first iteration required players to press a button to activate the hand drag, to push themselves. During testing, we quickly noticed that this wasn't intuitive for a lot of players and many players had issues timing the button presses correctly.  
The next iteration was inspired by [Subside](https://store.steampowered.com/app/2550040/Subside/). Their approach, which we also settled on, was to enable the hand drag when the hand orientation matches the movement direction. This sounds simple, but it did require a lot of extra iterations, tweaks and tricks to get it to feel right. Some of the little tweaks/tricks include:

- Remapping the hand velocity with a curve. This also limits the maximum hand velocity and thus the maximum swimming velocity.
- Changing the hand drag configuration based on the hand's speed.
- Not applying hand drag if the player is moving through the water but isn't moving their hand.
- Reducing the velocity change if the player is going backwards.

The most important trick, was to detect if the player was doing a breaststroke motion. Based on how much the movement looks like a breaststroke, I redirect the velocity change towards the camera direction. This makes it very intuitive for players to swim long distances, as they can simply swing their arms and look where they want to go. This solves a major issue where people would naturally lower their arms during their swing, causing them to push themselves upwards. At the same time, this system still gives players the freedom move backwards, sideways or vertically by pushing in those directions.

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/swimming/physical-swimming.mp4" type="video/mp4">
</video>

Another neat trick, was to store the velocity from landing in the water separately. This allowed me to split this part of the velocity off from the total velocity and to apply higher drag on it. This allowed me to tweak the drag so it felt good for swimming, while also being able to tweak a stronger drag that prevents you from hitting the bottom of the pool when you jump in.

Since the whole system is build around drag, it's also very easy to apply currents to the water. Drag is calculated based on the velocity of the object relative to the water. Simply subtracting the flow velocity from the objects velocity before applying the drag, and adding it back after, is enough to implement flowing water.  
A flow velocity which is higher than the maximum swimming velocity also automatically ensures that the player can't swim up against the flow.

{% highlight C++ %}
// Apply drag
const FVector StartVelocity = Velocity - FlowVelocity;
const FVector StartLandingVelocity = UVGMathLibrary::ClampedProjectOnToVector(StartVelocity, SwimmingState.LandingVelocity);
SwimmingState.LandingVelocity = UVGSwimmingUtils::ApplyDrag(StartLandingVelocity, Mass, SwimmingSettings->LandingDrag, DeltaSeconds);
const FVector StartBodyVelocity = StartVelocity - StartLandingVelocity;
Velocity = UVGSwimmingUtils::ApplyDrag(StartBodyVelocity, Mass, SwimmingSettings->BodyDrag, DeltaSeconds)
    + SwimmingState.LandingVelocity + FlowVelocity;

// ... Apply velocity from hands and stick movement input ...

// Make sure the LandingVelocity isn't higher than the Velocity
SwimmingState.LandingVelocity = UVGMathLibrary::ClampedProjectOnToVector(Velocity, SwimmingState.LandingVelocity);
{% endhighlight %}

{% endcapture_markdown %}

{% include card.html title="Physical Swimming" image="/assets/portfolio/unbound/swimming/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=swimming %}





{% capture_markdown sliding %}

The sliding system has 3 different slide 'styles' depending on angle of the ground.

### Horizontal Ground

On horizontal ground, the player can initiate a slide by crouching down while they're sprinting. This initiates a slide, with a configurable distance.  
I don't actually track the distance of the slide though. Instead, I apply a deceleration value to the current velocity, which I precalculated such that the slide will have the desired distance. I calculate the deceleration value using this formula:

$$\text{Deceleration} = \frac{\text{StartSpeed}^2 - {EndSpeed}^2}{2 \cdot Distance}$$

The advantage of this approach, is that it makes it simple to dynamically switch in and out of the 'horizontal ground' style depending on the angle of the ground. We can transition into this style at any speed and the system will be able to handle it. If you get onto horizontal ground with a lower speed, then the slide will simply be shorter.

The player can stop sliding by un-crouching. Or they can decelerate by pulling the joystick backwards, which will quickly stop and end the slide.

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/sliding/horizontal-ground.mp4" type="video/mp4">
</video>

### Shallow Slope

Between 15° and 35° is considered a 'shallow slope'. At these angles the player is still able to walk up the slope, and they can initiate a slide in the same way as on horizontal ground. The difference with this style, is that the player can keep sliding indefinitely. The player can also only slide down the slope. They can use their joystick to steer a bit, allowing them to deviate at most 20° from straight down the slope.  
The maximum speed, acceleration and deceleration are all driven by slope-angle curves, giving us full control over the feel of the slide.

The player is also still able to decelerate by pulling the joystick backwards, stopping and ending the slide.  
Un-crouching doesn't end the slide, as we want standing slides on steep slopes to be able to smoothly transition into shallow slopes.

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/sliding/shallow-slope.mp4" type="video/mp4">
</video>

### Steep Slope

Between 35° and 55° is considered a 'steep slope'. At these angles the player is no longer able to walk on the slope at all and they'll automatically begin sliding without being able to stop or slow down. These slopes are therefore useful as level edges, or as one-way barriers to prevent backtracking.
The player is still able to steer and jump, like on shallow slopes.

Beyond 55°, the slope is too steep to slide on and the player will fall instead.

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/sliding/steep-slope.mp4" type="video/mp4">
</video>

### Slope Visualization Tool

With these different slope metrics, it's important for level designers to be able to reliably create create slopes that are within a certain angle range. This is especially relevant with landscapes as it's easy to accidentally have a patch be either steeper or shallower than intended. A patch beyond 55° would cause the player to fall instead of slide. And a patch bellow 15° could unexpectedly end the slide in the middle of the slope.
Shallow patches on a steep slope are especially problematic, as you don't notice them if you're not actively pulling the joystick backwards. Meanwhile, a player might be able to exploit the shallow patches to walk and jump back up onto a steep slope, that is intended as a one-way barrier.

That's why I created a custom shader, which you can enable with a button in the editor, to visualize the slope angles. Horizontal ground in green, shallow slopes in yellow, steep slopes in orange and beyond 55° in red.
The shader is applied to the 'Player Collision' view mode to ensure that you see the actual slope value that'll be used in gameplay, instead of the approximation you'd get from applying the shader on the regular meshes.

![](/assets/portfolio/unbound/sliding/slope-visualization-tool.png)

{% endcapture_markdown %}

{% include card.html title="Sliding" image="/assets/portfolio/unbound/sliding/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=sliding %}





{% capture_markdown debug_tooling %}

In Mover, 'input commands' and the system's state ('sync states') are stored in structs of type `FMoverDataStructBase`. This way the entire state of the system is described by these data structs, making it easy to replicate over the network.  
I decided to leverage this for our debugging workflow, by creating an inherited `FVGMoverDataStructBase` type with [Visual Logger](https://dev.epicgames.com/documentation/en-us/unreal-engine/visual-logger-in-unreal-engine) integration. This allowed us to render useful visualizations and log the complete state of the system every frame. This was an incredibly useful tool, to quickly diagnose and debug problems with the locomotion system.

<video autoplay muted loop width="100%">
    <source src="/assets/portfolio/unbound/debug-tooling//visual-log-cropped.mp4" type="video/mp4">
</video>

{% highlight C++ %}
void FVGRopeSwingingSyncState::DebugDraw(const UVGMoverComponent* MoverComponent) const
{
    if (IsValid(HeldRope) && IsValid(HeldRope->SwingRoot)
        && IsValid(MoverComponent) && IsValid(MoverComponent->GetUpdatedComponent()))
    {
        // While the visual rope is held in the players hand,
        // the player capsule is the actual center of mass to which the "rope attaches".
        UE_VLOG_SEGMENT_THICK(MoverComponent, LogVGLocomotion, Log, 
            HeldRope->SwingRoot->GetComponentLocation(), 
            MoverComponent->GetUpdatedComponentTransform().GetLocation(),
            FColor::Green, 2, TEXT(""));
    }
}

#if ENABLE_VISUAL_LOG
void FVGRopeSwingingSyncState::GrabDebugSnapshot(const UVGMoverComponent* MoverComponent,
    FVisualLogStatusCategory& Category) const
{
    FVGMoverDataStructBase::GrabDebugSnapshot(MoverComponent, Category);

    if (IsValid(MoverComponent) && IsValid(MoverComponent->GetUpdatedComponent()))
    {
        const FQuat RopeOrientation = GetRopeOrientation(
            MoverComponent->GetUpdatedComponentTransform().GetLocation());
        Category.Add("RopeOrientation", RopeOrientation.Rotator().ToString());

        const float RopeAngle = UVGMathLibrary::GetAngleBetweenVectors(
            RopeOrientation.GetUpVector(), FVector::DownVector);
        Category.Add("RopeAngle", FString::SanitizeFloat(RopeAngle));
    }
}
#endif
{% endhighlight %}

Mover also has the `FMovementRecord` feature, where the name and translation of every movement is stored in a list. Epic wasn't really using this data yet, so I decided to also log it in the Visual Log. I logged an indexed list of movements and drew indexed lines to show the movement. 
If the player moved unexpectedly, this feature made it super easy to pinpoint exactly which movement step caused the issue.

![](/assets/portfolio/unbound/debug-tooling/move-record-visualization.png)

{% endcapture_markdown %}

{% include card.html title="Debug Tooling" image="/assets/portfolio/unbound/debug-tooling/teaser.png" excerpt="<mark>TODO</mark>" collapsed_content=debug_tooling %}