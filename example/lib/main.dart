import 'package:flutter/material.dart';
import 'package:flutter_advanced_canvas_editor/src/canvas_controller.dart';
import 'package:flutter_advanced_canvas_editor/src/canvas.dart';
import 'package:flutter_advanced_canvas_editor/src/canvas_layer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CanvasController controller;
  bool isDrawing = false;
  bool isErasing = false;
  bool _layerPanelExpanded = false;

  @override
  void initState() {
    super.initState();
    controller = CanvasController(
      (pngBytes) {
        print('PNG bytes exporting canvas: $pngBytes');
      },
      onUndo: () {
        print('Undo action triggered - validation flags reset');
      },
      onRedo: () {
        print('Redo action triggered - validation flags reset');
      },
      onErase: () {
        print('Erase mode enabled - validation flags reset');
      },
    );

    // Set state callback once in initState
    controller.setOnStateChanged((isDrawing, isErasing) {
      if (mounted) {
        setState(() {
          this.isDrawing = isDrawing;
          this.isErasing = isErasing;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Layer navbar at top (collapsible)
              LayerNavBar(
                controller: controller,
                isExpanded: _layerPanelExpanded,
                onToggle: () {
                  setState(() {
                    _layerPanelExpanded = !_layerPanelExpanded;
                  });
                },
              ),

              // Main content
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: CanvasWidget(controller: controller, backgroundImage: 'assets/images/background.png', iconsSize: 25.0,),
                      ),
                    ),
                    CustomDraggableItems(controller: controller, items: [
                      Image.asset('assets/images/vehicle.png', width: 50, height: 50),
                      Image.asset('assets/images/vehicle.png', width: 50, height: 50),
                      // Add more items here
                    ]),
                    CustomActionButtons(controller: controller, buttons: [
                      IconButton(icon: Icon(Icons.undo), onPressed: controller.undo),
                      IconButton(icon: Icon(Icons.redo), onPressed: controller.redo),
                      IconButton(icon: Icon(Icons.delete), onPressed: controller.clearAll),
                      IconButton(
                        icon: Icon(Icons.edit),
                        color: !controller.isDrawing ? Colors.black : Colors.red,
                        onPressed: !controller.isDrawing ? controller.enableDrawing : controller.disableDrawingErasing,
                      ),
                      IconButton(
                        icon: Icon(Icons.brush),
                        color: !controller.isErasing ? Colors.black : Colors.red,
                        onPressed: !controller.isErasing ? controller.enableErasing : controller.disableDrawingErasing,
                      ),
                      IconButton(icon: Icon(Icons.save), onPressed: controller.exportCanvas),
                    ]),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Drawing: $isDrawing, Erasing: $isErasing'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomDraggableItems extends StatelessWidget {
  final CanvasController controller;
  final List<Widget> items;

  CustomDraggableItems({required this.controller, required this.items});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Disable drawing and erasing when the drag interaction starts
      onPanStart: (onPanStart) {
        controller.disableDrawingErasing();
      },
      // Disable drawing and erasing when the drag interaction ends
      onPanEnd: (onPanEnd) {
        controller.disableDrawingErasing();
      },
      child: Container(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Draggable<Widget>(
                data: item,
                feedback: item,
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: item,
                ),
                child: item,
                // Disable drawing and erasing when the drag interaction starts
                onDragStarted: () {
                  controller.disableDrawingErasing();
                },
                // Optionally, you can disable drawing and erasing when the drag interaction is completed or canceled
                onDragEnd: (details) {
                  controller.disableDrawingErasing();
                },
                onDraggableCanceled: (velocity, offset) {
                  controller.disableDrawingErasing();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CustomActionButtons extends StatelessWidget {
  final CanvasController controller;
  final List<Widget> buttons;

  CustomActionButtons({required this.controller, required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons,
    );
  }
}

// ==================== Layer Navbar Widget ====================

class LayerNavBar extends StatelessWidget {
  final CanvasController controller;
  final bool isExpanded;
  final VoidCallback onToggle;

  const LayerNavBar({
    Key? key,
    required this.controller,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header bar (always visible)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: onToggle,
                  tooltip: isExpanded ? 'Collapse Layers' : 'Expand Layers',
                ),
                Text('Layers (${controller.layers.length})',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.add, size: 20),
                  onPressed: controller.createLayer,
                  tooltip: 'Add Layer',
                ),
                SizedBox(width: 8),
                // Show current layer info in collapsed state
                if (!isExpanded)
                  Expanded(
                    child: Text(
                      'Active: ${controller.currentLayer?.name ?? "None"}',
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Expandable layer list
          if (isExpanded)
            Container(
              key: ValueKey('layer_list_${controller.layers.length}'),
              height: 200,
              color: Colors.grey[200],
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.all(8),
                itemCount: controller.layers.length,
                itemBuilder: (context, index) {
                  // Reverse index for top-to-bottom display (left to right)
                  final reverseIndex = controller.layers.length - 1 - index;
                  final layer = controller.layers[reverseIndex];
                  final isActive = controller.currentLayerIndex == reverseIndex;

                  return LayerCard(
                    key: ValueKey(layer.id),
                    layer: layer,
                    layerIndex: reverseIndex,
                    isActive: isActive,
                    controller: controller,
                    onTap: () {
                      controller.setCurrentLayer(reverseIndex);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class LayerCard extends StatefulWidget {
  final CanvasLayer layer;
  final int layerIndex;
  final bool isActive;
  final CanvasController controller;
  final VoidCallback onTap;

  const LayerCard({
    Key? key,
    required this.layer,
    required this.layerIndex,
    required this.isActive,
    required this.controller,
    required this.onTap,
  }) : super(key: key);

  @override
  _LayerCardState createState() => _LayerCardState();
}

class _LayerCardState extends State<LayerCard> {
  bool _isRenaming = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.layer.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 180,
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.isActive ? Colors.blue[100] : Colors.white,
          border: Border.all(
            color: widget.isActive ? Colors.blue : Colors.grey[300]!,
            width: widget.isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Layer name (editable)
            _isRenaming
                ? TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    ),
                    onSubmitted: (value) {
                      widget.controller.renameLayer(widget.layerIndex, value);
                      setState(() {
                        _isRenaming = false;
                      });
                    },
                  )
                : GestureDetector(
                    onDoubleTap: () {
                      setState(() {
                        _isRenaming = true;
                      });
                    },
                    child: Text(
                      widget.layer.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

            SizedBox(height: 8),

            // Controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Visibility toggle
                IconButton(
                  icon: Icon(
                    widget.layer.visible ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                  ),
                  onPressed: () {
                    widget.controller.setLayerVisibility(
                      widget.layerIndex,
                      !widget.layer.visible,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  tooltip: widget.layer.visible ? 'Hide' : 'Show',
                ),

                // Lock toggle
                IconButton(
                  icon: Icon(
                    widget.layer.locked ? Icons.lock : Icons.lock_open,
                    size: 20,
                  ),
                  onPressed: () {
                    widget.controller.setLayerLocked(
                      widget.layerIndex,
                      !widget.layer.locked,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  tooltip: widget.layer.locked ? 'Unlock' : 'Lock',
                ),

                // More options menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    switch (value) {
                      case 'duplicate':
                        widget.controller.duplicateLayer(widget.layerIndex);
                        break;
                      case 'merge_down':
                        widget.controller.mergeLayerDown(widget.layerIndex);
                        break;
                      case 'clear':
                        widget.controller.clearLayer(widget.layerIndex);
                        break;
                      case 'delete':
                        widget.controller.deleteLayer(widget.layerIndex);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'duplicate', child: Text('Duplicate', style: TextStyle(fontSize: 12))),
                    PopupMenuItem(
                      value: 'merge_down',
                      child: Text('Merge Down', style: TextStyle(fontSize: 12)),
                      enabled: widget.layerIndex > 0,
                    ),
                    PopupMenuItem(value: 'clear', child: Text('Clear', style: TextStyle(fontSize: 12))),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(fontSize: 12)),
                      enabled: widget.controller.layers.length > 1,
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 8),

            // Opacity slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Opacity: ${(widget.layer.opacity * 100).round()}%',
                    style: TextStyle(fontSize: 11)),
                Slider(
                  value: widget.layer.opacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (value) {
                    widget.controller.setLayerOpacity(widget.layerIndex, value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
