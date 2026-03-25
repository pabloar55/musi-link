import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musi_link/models/message.dart';
import 'package:musi_link/widgets/chat/message_bubble.dart';

void main() {
  group('MessageBubble', () {
    final timestamp = DateTime(2025, 6, 15, 14, 5);
    const colorScheme = ColorScheme.dark();

    Widget buildBubble({required Message message, required bool isMe}) {
      return MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: isMe,
            colorScheme: colorScheme,
          ),
        ),
      );
    }

    testWidgets('muestra texto del mensaje', (tester) async {
      final message = Message(
        id: 'msg1',
        senderId: 'user1',
        text: 'Hola, ¿qué tal?',
        timestamp: timestamp,
      );

      await tester.pumpWidget(buildBubble(message: message, isMe: true));

      expect(find.text('Hola, ¿qué tal?'), findsOneWidget);
    });

    testWidgets('muestra hora formateada HH:mm', (tester) async {
      final message = Message(
        id: 'msg1',
        senderId: 'user1',
        text: 'Test',
        timestamp: timestamp,
      );

      await tester.pumpWidget(buildBubble(message: message, isMe: true));

      expect(find.text('14:05'), findsOneWidget);
    });

    testWidgets('muestra icono done cuando isMe y no leído', (tester) async {
      final message = Message(
        id: 'msg1',
        senderId: 'user1',
        text: 'Test',
        timestamp: timestamp,
        read: false,
      );

      await tester.pumpWidget(buildBubble(message: message, isMe: true));

      expect(find.byIcon(Icons.done), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsNothing);
    });

    testWidgets('muestra icono done_all cuando isMe y leído', (tester) async {
      final message = Message(
        id: 'msg1',
        senderId: 'user1',
        text: 'Test',
        timestamp: timestamp,
        read: true,
      );

      await tester.pumpWidget(buildBubble(message: message, isMe: true));

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('no muestra iconos de check cuando no es mío', (tester) async {
      final message = Message(
        id: 'msg1',
        senderId: 'user2',
        text: 'Test',
        timestamp: timestamp,
        read: true,
      );

      await tester.pumpWidget(buildBubble(message: message, isMe: false));

      expect(find.byIcon(Icons.done), findsNothing);
      expect(find.byIcon(Icons.done_all), findsNothing);
    });

    testWidgets('alineación a la derecha cuando isMe', (tester) async {
      final message = Message(
        id: 'msg1',
        senderId: 'user1',
        text: 'Test',
        timestamp: timestamp,
      );

      await tester.pumpWidget(buildBubble(message: message, isMe: true));

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('alineación a la izquierda cuando no isMe', (tester) async {
      final message = Message(
        id: 'msg1',
        senderId: 'user2',
        text: 'Test',
        timestamp: timestamp,
      );

      await tester.pumpWidget(buildBubble(message: message, isMe: false));

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('hora con padding de ceros (09:03)', (tester) async {
      final message = Message(
        id: 'msg1',
        senderId: 'user1',
        text: 'Mañana',
        timestamp: DateTime(2025, 1, 1, 9, 3),
      );

      await tester.pumpWidget(buildBubble(message: message, isMe: false));

      expect(find.text('09:03'), findsOneWidget);
    });
  });
}
