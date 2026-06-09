```@meta
CurrentModule = PetoiBittle
```

# Gaits

Gaits are **continuous locomotion patterns**: the robot keeps moving in the requested manner
until you send a different command (for example a posture such as [`PetoiBittle.balance`](@ref)
to stop and stand). Each gait comes in forward / left / right variants where the firmware
supports them.

## Use case: walk around, then stop

```julia
using PetoiBittle

connection = PetoiBittle.connect(PetoiBittle.find_bittle_port())

PetoiBittle.walk_forward(connection)   # start walking forward
sleep(3)                               # let it walk for a few seconds
PetoiBittle.walk_left(connection)      # curve to the left
sleep(3)
PetoiBittle.balance(connection)        # stop and stand still

PetoiBittle.disconnect(connection)
```

!!! tip
    Trotting is faster than walking; crawling keeps the body lower and more stable. Pick the
    gait that matches your surface and speed needs.

## Reference

```@docs
PetoiBittle.WalkForward
PetoiBittle.walk_forward
PetoiBittle.WalkLeft
PetoiBittle.walk_left
PetoiBittle.WalkRight
PetoiBittle.walk_right
PetoiBittle.TrotForward
PetoiBittle.trot_forward
PetoiBittle.TrotLeft
PetoiBittle.trot_left
PetoiBittle.TrotRight
PetoiBittle.trot_right
PetoiBittle.CrawlForward
PetoiBittle.crawl_forward
PetoiBittle.CrawlLeft
PetoiBittle.crawl_left
PetoiBittle.CrawlRight
PetoiBittle.crawl_right
PetoiBittle.Backward
PetoiBittle.walk_backward
PetoiBittle.BackwardLeft
PetoiBittle.walk_backward_left
PetoiBittle.BackwardRight
PetoiBittle.walk_backward_right
PetoiBittle.Stepping
PetoiBittle.step_in_place
PetoiBittle.Bound
PetoiBittle.bound_forward
```
