Monjolo
=======

Monjolo sensors are designed to meter energy consumers, such as plug loads,
lighting, water heaters, etc. Monjolo exploits an interesting fact to accomplish
this: energy consuming loads (e.g. overhead lighting) often produce side
channels of energy that can be harvested (e.g. light with a solar panel).
Monjolo nodes use an energy-harvesting power supply to scavenge energy from
these side channels to power themselves. The sensors then infer information
about the original load based on the rate it is able to harvest. Monjolo nodes
follow a simple principle: the faster the rate of harvesting the greater the
amount of energy consumed by the monitored load.

The operation of a Monjolo node proceeds as follows: the harvester charges
a capacitor to some threshold. Once the threshold is met, the processing
core of the node activates and transmits a packet. The capacitor is then
drained to a lower threshold where the processing core is disabled and
the recharging process recommences. A central receiver collects all of these
packets and calculates the activation rate of the Monjolo node. This rate
is then used to meter the energy consumer.

This differs from traditional sensing because there is no explicit sensor
on the device. The sensing apparatus is entirely composed of the
energy-harvester and the packet receiver. All information is contained in
the rate of activations of the Monjolo node.

We have developed Three instantiations of this metering design. First is
Coilcube, a power meter for AC loads. Second is a light sensor for metering
lighting. And third is a thermoelectric design for metering temperature
differential.


Coilcube
--------

[
![cc_case](https://raw.github.com/lab11/monjolo/master/media/coilcube_case_269x350.jpg)
](https://raw.github.com/lab11/monjolo/master/media/coilcube_case.jpg)
[
![cc_open](https://raw.github.com/lab11/monjolo/master/media/coilcube_open_400x350.jpg)
](https://raw.github.com/lab11/monjolo/master/media/coilcube_open.jpg)

Coilcube is an AC power meter that comes in two forms: plug-load and split-core.



