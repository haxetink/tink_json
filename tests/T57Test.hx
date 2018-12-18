package;

import tink.unit.Assert.*;
import tink.Json.*;
import tink.json.Serialized;

typedef DebrisStruct = {
    name: String,
    min: Int,
    max: Int,
    chance: Int,
}

typedef DialogueNode = {
    id: Int,
    name: String,
    positionInEditorX: Int,
    positionInEditorY: Int,
    answer: Array<String>,
    childrenID: Array<Int>,
    actionKey: Int,
    actionValue: String,
    conditionKey: Int,
    conditionValue: String,
    cost: Int,
    isPlayerReply: Bool,
    isSecondRoot: Bool,
}

enum ECSComponent {
    @:json({ name: 'ECSComponentAnimation' }) ECSComponentAnimation(
        editorIndex: Int,
        currentFrame: Int, frameCount: Int, frameRate: Int,
        atlasOriginX: Int, atlasOriginY: Int, atlasWidth: Int, atlasHeight: Int,
        transformWidth: Int, transformHeight: Int,
        flip: Int,
        minLoopPause: Int, maxLoopPause: Int,
        paused: Bool, reversed: Bool,
        removeEntityOnCompletion: Bool,
        loops: Bool,
        removeAfterLoop: Bool,
        reverseAfterLoop: Bool,
        textureName: String
    );
    @:json({ name: 'ECSComponentAudioTrigger' }) ECSComponentAudioTrigger( filenames: Array<String>, range: Int );
    @:json({ name: 'ECSComponentBodyPart' }) ECSComponentBodyPart(
        partIndex: Int,
        anims: Array<ECSComponent>, // TODO (DK) ECSComponentAnimation only
        animOffsets: Array<{ x: Int, y: Int }>,
        animMap: Array<{ type: Int, direction: Int }>
    );
    @:json({ name: 'ECSComponentBoundingBox' }) ECSComponentBoundingBox( x: Float, y: Float, width: Int, height: Int );
    @:json({ name: 'ECSComponentCeilingDrop' }) ECSComponentCeilingDrop( triggerDistance: Int );
    @:json({ name: 'ECSComponentChild' }) ECSComponentChild( parentPrefabName: String, parentID: Int, parentOffsetX: Int, parentOffsetY: Int, inheritsRotation: Bool );
    @:json({ name: 'ECSComponentCollectible' }) ECSComponentCollectible( monetaryValue: Float, healthBonus: Float, ammoBonus: Int, manaBonus: Int );
    @:json({ name: 'ECSComponentCollider' }) ECSComponentCollider( category: Int, mask: Int, pixelPerfect: Bool );
    @:json({ name: 'ECSComponentCover' }) ECSComponentCover( enabled: Bool, reversed: Bool );
    @:json({ name: 'ECSComponentCutScene' }) ECSComponentCutScene( filename: String, progressRequirement: Int, removeAfterCut: Bool );
    @:json({ name: 'ECSComponentDebris' }) ECSComponentDebris( debrisStructs: Array<DebrisStruct>, spawnOnHit: Bool );
    @:json({ name: 'ECSComponentDoor' }) ECSComponentDoor( closeTimer: Int, lockOnTimeOut: Bool, collidesWithBullets: Bool, hackable: Bool );
    @:json({ name: 'ECSComponentElevator' }) ECSComponentElevator(
        direction: Int,
        nextLevel: String,
        nextSpawnPoint: String,
        originX: Int,
        originY: Int,
        layerUp: Bool,
        enabled: Bool
    );
    @:json({ name: 'ECSComponentEnemy' }) ECSComponentEnemy( difficulty: Int );
    @:json({ name: 'ECSComponentExplodable' }) ECSComponentExplodable( layer: Int, prefab: String, ?damage: Int );
    @:json({ name: 'ECSComponentHitPoints' }) ECSComponentHitPoints( hitPoints: Float, successor: String, minTicksForHit: Int, useWhiteMask: Bool, showHPBar: Bool, rammable: Bool, transferDamageToSuccessor: Bool );
    @:json({ name: 'ECSComponentHumanoid' }) ECSComponentHumanoid( autoAdjustUpperBody: Bool, syncLegsToTorso: Bool, choppable: Bool, spawnFootprints: Bool, lastDirectionIndex: Int );
    @:json({ name: 'ECSComponentItem' }) ECSComponentItem( key: String, security: Int, bounces: Int, description: String, shopIcon: String, shopCloseUp: String, bodyPartPrefix: String );
    @:json({ name: 'ECSComponentLevelChange' }) ECSComponentLevelChange( nextLevel: String, nextSpawn: String );
    @:json({ name: 'ECSComponentLight' }) ECSComponentLight( r: Int, g: Int, b: Int, intensity: Int );
    @:json({ name: 'ECSComponentLookAt' }) ECSComponentLookAt;
    @:json({ name: 'ECSComponentMarker' }) ECSComponentMarker;
    @:json({ name: 'ECSComponentNPC' }) ECSComponentNPC( dialogueNodes: Array<DialogueNode> );
    @:json({ name: 'ECSComponentPathBasedMovement' }) ECSComponentPathBasedMovement(
        minRange: Int, maxRange: Int, pauseDuration: Int, minChaseDistance: Int, maxChaseDistance: Int,
        speed: Float, chasingSpeed: Float, _default_: Int, onHit: Int, lookDuringChase: Bool, chasingRange: Int
    );
    @:json({ name: 'ECSComponentPlayerSpawn' }) ECSComponentPlayerSpawn( saveGame: Bool );
    @:json({ name: 'ECSComponentRender' }) ECSComponentRender(
        atlas: String, atlasX: Int, atlasY: Int, atlasWidth: Int, atlasHeight: Int,
        layerIndex: Int, layerZ: Int,
        blendMode: Int, red: Int, green: Int, blue: Int, alpha: Int,
        flip: Int, alwaysVisible: Bool
    );
    @:json({ name: 'ECSComponentShooter' }) ECSComponentShooter(
          shootingAngleOffset: Float,
          maxShootingDistance: Int,
          canShootWhileMoving: Bool,
          canShootWhileRoaming: Bool,
          canShootWhilePatrolling: Bool,
          restrictShootingDirection: Bool
    );
    @:json({ name: 'ECSComponentSort' }) ECSComponentSort;
    @:json({ name: 'ECSComponentSpawner' }) ECSComponentSpawner(
          startDelay: Int,
          spawnCount: Int,
          spawnDelay: Int,
          resetAfterSpawn: Bool,
          randomizePosition: Bool,
          active: Bool,
          spawnPause: Int,
          spawnAngle: Float,
          spawnAngleInc: Float,
          spawned: Array<String>
    );
    @:json({ name: 'ECSComponentSpike' }) ECSComponentSpike( startOffset: Int, onTicks: Int, offTicks: Int, damage: Float );
    @:json({ name: 'ECSComponentTerminal' }) ECSComponentTerminal( items: Array<Int /* TODO (DK) proper type */>, news: Array<{ prefab: String } /* TODO (DK) separate type */>, header: String, withAds: Bool );
    @:json({ name: 'ECSComponentTilemapCollider' }) ECSComponentTilemapCollider( layerMask: Int, exclusive: Bool );
    @:json({ name: 'ECSComponentTransform' }) ECSComponentTransform( x: Float, y: Float, width: Int, height: Int, pivotX: Int, pivotY: Int, rotation: Float );
    @:json({ name: 'ECSComponentTransformTarget' }) ECSComponentTransformTarget;
    @:json({ name: 'ECSComponentTrigger' }) ECSComponentTrigger(
        enabled: Bool, requiresInteraction: Bool, transferToSuccessor: Bool, removeAfterTrigger: Bool, invisible: Bool, playerExclusive: Bool,
        enabledWhenEnemyTargetsDead: Bool,
        onEnterAction: Int, onExitAction: Int, onRemovedAction: Int,
        targetX: Int, targetY: Int, targetIDs: Array<Int>, targetTiles: Array<Int /* ??? */>,
        lines: Array<String>
    );
    @:json({ name: 'ECSComponentUI' }) ECSComponentUI( uiName: String, alwaysInFront: Bool );
    @:json({ name: 'ECSComponentWeapon' }) ECSComponentWeapon( weapons: Array<Entity> );
    @:json({ name: 'ECSComponentWeaponItem' }) ECSComponentWeaponItem(
        gunName: String, gunPrefab: String, bulletPrefab: String, effectPrefab: String, shellPrefab: String, bulletOffsets: Array<{ x: Int, y: Int }>,
        animationIndex: Int, cooldown: Int, warmUp: Int, bulletCount: Int, spreadMin: Float, spreadMax: Float, damage: Float, recoil: Float,
        maxBullets: Int, maxDistance: Int, ?maxClips: Int, spreadRandom: Bool, secondary: Bool, melee: Bool, warmUpAfterEveryShot: Bool
    );
}

typedef Entity = {
    id: Int,
    name: String,
    category: String,
    visible: Bool,
    components: Array<ECSComponent>,
}

typedef Tile = {
    position: {
        x: Int,
        y: Int,
    },
    tileIndex: Int,
    layerIndex: Int,
}

// layers [floor, decals, cast shadow, walls, ceiling]

typedef Layer = {
    name: String,
    tileArray: Array<Tile>,
}

typedef Tilemap = {
    introImage: String,
    musicTrack: String,
    bgRed: Int,
    bgGreen: Int,
    bgBlue: Int,
    map: {
        mapWidth: Int,
        mapHeight: Int,
        tileWidth: Int,
        tileHeight: Int,
        layerCount: Int,
        localTilesetName: String,
        mapAmbient: Int,
        layerArray: Array<Layer>,
    },
    entities: Array<Entity>,
}

class T57Test {
	public function new() {
	}

	public function read() {
		var m: Tilemap = parse('{}');
		return assert(m != null);
	}
}
