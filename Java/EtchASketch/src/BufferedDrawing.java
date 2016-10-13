import gnu.io.CommPort;
import gnu.io.CommPortIdentifier;
import gnu.io.PortInUseException;
import gnu.io.SerialPort;
import gnu.io.SerialPortEvent;
import gnu.io.SerialPortEventListener;

import java.awt.BasicStroke;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.TooManyListenersException;

import javax.imageio.ImageIO;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JSpinner;
import javax.swing.JTextArea;
import javax.swing.SpinnerModel;
import javax.swing.SpinnerNumberModel;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

public class BufferedDrawing extends JFrame implements ActionListener,
		SerialPortEventListener, ChangeListener {
	private JButton leftButton = new JButton("Left");
	private JButton rightButton = new JButton("Right");
	private JButton upButton = new JButton("Up");
	private JButton downButton = new JButton("Down");
	private JButton s1Button = new JButton("S1");
	private JButton s2Button = new JButton("S2");
	private JButton clearButton = new JButton("Clear");
	private JButton connectButton = new JButton("Connect");
	private JButton disconnectButton = new JButton("Disconnect");
	private JButton saveButton = new JButton("Save Image");
	private JPanel colors = new JPanel();
	//private SerialComm comm = new SerialComm();
	private JComboBox choice = new JComboBox();
	private JLabel currentColor = new JLabel("Color");
	private JLabel keyInput = new JLabel("Keyboard Input");
	private String keyString = "";
	private int currentx = 100;
	private int currenty = 200;
	private int previousX = 0;
	private int previousY = 0;
	private char inputType = 0;
	private int colorCount = 0;
	private String tempRed = "";
	private String tempBlue = "";
	private String tempGreen = "";
	private boolean nextIsColor = false;
	private boolean nextIsX = false;
	private boolean nextIsY = false;
	private boolean nextIsSize = false;
	private Enumeration ports = null;
	private HashMap<String, CommPortIdentifier> portMap = new HashMap<String, CommPortIdentifier>();
	private InputStream input = null;
	private OutputStream output = null;
	private CommPortIdentifier selectedPortIdentifier = null;
	private SerialPort serialPort = null;
	final static int TIMEOUT = 2000;
	private JTextArea status = new JTextArea();
	byte press = 0;
	boolean wait = false;
	boolean inputReady = false;
	private BufferedImage image; // buffered image used for canvas
	private Graphics2D g2d; // graphics of the canvas
	private int count = 0;
	SpinnerModel model = new SpinnerNumberModel(1, 1, 7, 1); // Spinner model;
																// Numbers 1-7
	JSpinner strokeSize = new JSpinner(model); // The actual Spinner
	JPanel Canvas;

	public void disconnect() {
		try {
			status.setText("Disconnected");
			System.out.println("Disconnected");
			serialPort.removeEventListener();
			serialPort.close();
			input.close();
			output.close();
		} catch (Exception e) {
			status.setText("Failed to disconnect");
		}
	}

	public void resetCursor() {
		writeData(setByte(false, false, false, false, false, (char) 12));
		writeData(setByte(false, false, false, true, false, (char) 12));
		writeData(setByte(false, false, false, false, false, (char) 12));
		writeData(setByte(false, false, false, false, true, (char) 12));
		writeData(setByte(false, false, false, true, true, (char) 12));
		writeData(setByte(false, false, false, false, true, (char) 12));
	}

	public void setWait(boolean bool) {
		wait = bool;
	}

	public void writeData(byte b) {
		try {
			output.write(b);
			output.flush();
		} catch (IOException e) {
			status.setText("failed to write");
		}
	}

	public boolean initIOStream() {
		boolean success = false;
		try {
			input = serialPort.getInputStream();
			output = serialPort.getOutputStream();
			String str = "New Game? (y/n)";
			resetCursor();
			for (int i = 0; i < str.length(); i++) {
				writeData(setByte(false, false, true, false, false,
						str.charAt(i)));
				writeData(setByte(false, false, true, true, false,
						str.charAt(i)));
				writeData(setByte(false, false, true, false, false,
						str.charAt(i)));
				writeData(setByte(false, false, true, false, true,
						str.charAt(i)));
				writeData(setByte(false, false, true, true, true, str.charAt(i)));
				writeData(setByte(false, false, true, false, true,
						str.charAt(i)));
			}
			System.out.println("IO");
			success = true;
		} catch (IOException e) {
			status.setText("IO Stream Failed");
		}
		return success;
	}

	public void connect(String s) {
		selectedPortIdentifier = (CommPortIdentifier) portMap.get(s);
		CommPort commPort = null;
		System.out.println("connecting...");
		try {
			commPort = selectedPortIdentifier.open("Etch", TIMEOUT);
			serialPort = (SerialPort) commPort;
			System.out.println("connect");
			status.setText("Connected");
			serialPort.setSerialPortParams(9600, SerialPort.DATABITS_8,
					SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);

		} catch (PortInUseException e) {
			status.setText("Port In Use");
			System.out.println("Port In Use");
		} catch (Exception e) {
			status.setText("Connection Failed");
			System.out.println("connect failed");
		}
	}

	public byte getPress() {
		return press;
	}

	public boolean waitForInput() {
		return inputReady;
	}

	public void clearInputReady() {
		inputReady = false;
	}

	public void initListener() {
		try {
			serialPort.addEventListener(this);
			serialPort.notifyOnDataAvailable(true);
		} catch (TooManyListenersException e) {
			status.setText("Too Many Listeners");
		}
	}

	public byte setByte(boolean lookout, boolean Load, boolean RS, boolean EN,
			boolean NS, char c) {
		byte b = 0;
		if (Load) {
			b = (byte) (b - 128);
		}
		if (lookout) {
			b = (byte) (b + 64);
		}
		if (RS) {
			b = (byte) (b + 32);
		}
		if (EN) {
			b = (byte) (b + 16);
		}
		if (!NS) {
			byte temp = (byte) (c / 16);
			if (temp % 2 == 1) {
				b = (byte) (b + 1);
			}
			temp = (byte) (temp / 2);
			if (temp % 2 == 1) {
				b = (byte) (b + 2);
			}
			temp = (byte) (temp / 2);
			if (temp % 2 == 1) {
				b = (byte) (b + 4);
			}
			temp = (byte) (temp / 2);
			if (temp % 2 == 1) {
				b = (byte) (b + 8);
			}
		} else {
			byte temp = (byte) (c);
			if (temp % 2 == 1) {
				b = (byte) (b + 1);
			}
			temp = (byte) (temp / 2);
			if (temp % 2 == 1) {
				b = (byte) (b + 2);
			}
			temp = (byte) (temp / 2);
			if (temp % 2 == 1) {
				b = (byte) (b + 4);
			}
			temp = (byte) (temp / 2);
			if (temp % 2 == 1) {
				b = (byte) (b + 8);
			}
		}
		return b;
	}

	public JComboBox<String> search() {
		JComboBox<String> Result = new JComboBox<String>();
		ports = CommPortIdentifier.getPortIdentifiers();
		while (ports.hasMoreElements()) {
			CommPortIdentifier curPort = (CommPortIdentifier) ports
					.nextElement();
			if (curPort.getPortType() == CommPortIdentifier.PORT_SERIAL) {
				Result.addItem(curPort.getName());
				System.out.println(curPort.getName());
				portMap.put(curPort.getName(), curPort);
			}
		}
		return Result;
	}

	public BufferedDrawing(String title) {
		super(title);
		setSize(800, 600);
		image = new BufferedImage(256, 256, BufferedImage.TYPE_INT_ARGB);
		g2d = (Graphics2D) image.getGraphics();
		g2d.setColor(Color.BLACK);
		Canvas = new JPanel() {
			public void paintComponent(Graphics g) {
				g.drawImage(image, 200, 50, Color.WHITE, null); // Paints just
																// the image as
																// the canvas
			}
		};

		JPanel buttons = new JPanel(); // Groups the button and Jspinner
										// together
		buttons.add(upButton);
		buttons.add(downButton);
		buttons.add(leftButton);
		buttons.add(rightButton);
		buttons.add(s1Button);
		buttons.add(s2Button);
		buttons.add(clearButton);
		colors.setBackground(new Color(0, 0, 0));
		buttons.add(connectButton);
		buttons.add(disconnectButton);
		// buttons.add(saveButton);
		choice = search();
		buttons.add(choice);
		buttons.add(new JLabel("    Stroke Size:")); // Labels the JSpinner
		buttons.add(strokeSize);
		buttons.add(currentColor);
		currentColor.setText("Color: 000000");
		buttons.add(colors);
		// buttons.add(keyInput);
		keyInput.setText("Input: ");
		add(buttons, BorderLayout.NORTH);
		add(Canvas);

		rightButton.addActionListener(this);
		leftButton.addActionListener(this);
		upButton.addActionListener(this);
		downButton.addActionListener(this);
		s1Button.addActionListener(this);
		s2Button.addActionListener(this);
		connectButton.addActionListener(this);
		disconnectButton.addActionListener(this);
		clearButton.addActionListener(this);
		saveButton.addActionListener(this);
		strokeSize.addChangeListener(this); // Listens to the status of the
											// JSpinner
	}

	@Override
	public void actionPerformed(ActionEvent e) {
		if (e.getSource().equals(rightButton)) {
			currentx += 1;
			Integer x = currentx;
			Integer y = currenty;
			Integer width = 1;
			Integer height = 1;
			g2d.drawRect(x, y, width, height);
			repaint();
		}

		else if (e.getSource().equals(upButton)) {
			currenty -= 1;
			Integer x = currentx;
			Integer y = currenty;
			Integer width = 1;
			Integer height = 1;
			g2d.drawRect(x, y, width, height);
			repaint();
		}

		else if (e.getSource().equals(leftButton)) {
			currentx -= 1;
			Integer x = currentx;
			Integer y = currenty;
			Integer width = 1;
			Integer height = 1;
			g2d.drawRect(x, y, width, height);
			repaint();
		} else if (e.getSource().equals(downButton)) {
			currenty += 1;
			Integer x = currentx;
			Integer y = currenty;
			Integer width = 1;
			Integer height = 1;
			g2d.drawRect(x, y, width, height);
			repaint();
		} else if (e.getSource().equals(s1Button)) {
			Canvas.setSize(256, 256);
			image = new BufferedImage(256, 256, BufferedImage.TYPE_INT_ARGB);
			this.repaint();
			this.revalidate();
			g2d = (Graphics2D) image.getGraphics();
			g2d.setColor(Color.BLACK);
		} else if (e.getSource().equals(s2Button)) {
			Canvas.setSize(362, 362);
			image = new BufferedImage(362, 362, BufferedImage.TYPE_INT_ARGB);
			this.repaint();
			this.revalidate();
			g2d = (Graphics2D) image.getGraphics();
			g2d.setColor(Color.BLACK);
		} else if (e.getSource().equals(clearButton)) {
			Integer x = 0;
			Integer y = 0;
			Integer width = 362;
			Integer height = 362;
			g2d.setColor(Color.WHITE);
			g2d.fillRect(x, y, width, height);
			g2d.setColor(new Color(255, 0, 255));
			repaint();
		} else if (e.getSource().equals(connectButton)) {
			connect((String) choice.getSelectedItem());
			initIOStream();
			initListener();
		} else if (e.getSource().equals(disconnectButton)) {
			disconnect();
		} else if (e.getSource().equals(saveButton)) {
			try {
				File outputfile = new File("SavedImage.png");
				ImageIO.write(image, "png", outputfile);
				System.out.println("Image Saved");
			} catch (IOException e1) {
				System.out.println("failed to save");
			}
		}
	};

	@Override
	public void stateChanged(ChangeEvent e) {
		if (e.getSource().equals(strokeSize)) {
			Integer val = (Integer) strokeSize.getValue();
			g2d.setStroke(new BasicStroke((float) val));
		}
	}

	@Override
	public void serialEvent(SerialPortEvent e) {
		if (e.getEventType() == SerialPortEvent.DATA_AVAILABLE) {
			try {
				if (wait) {
					input.skip(1);
					inputReady = false;
					wait = false;
				} else {
					press = (byte) input.read();
					// System.out.println(press);
					inputReady = true;
					writePot();
				}
			} catch (Exception E) {
				status.setText("waiting for input");
			}
		}

	}

	public void writePot() {
		try {
			inputType = (char) getPress();
			System.out.println(inputType);
			if (nextIsX == true || nextIsY == true || nextIsColor == true) {
				keyString = keyString + inputType;
				keyInput.setText("Input: " + keyString);
				if (nextIsX == true) {
					currentx = getPress() & 0xFF;
					System.out.println("X set to" + currentx);
					count++;
					nextIsX = false;
				} else if (nextIsY == true) {
					currenty = getPress() & 0xFF;
					System.out.println("Y is set to" + currenty);
					count++;
					nextIsY = false;
				} /*
				 * else if (nextIsSize) { if(getPress() == 1){
				 * Canvas.setSize(256, 256); image = new BufferedImage(256, 256,
				 * BufferedImage.TYPE_INT_ARGB); this.repaint();
				 * this.revalidate(); g2d = (Graphics2D) image.getGraphics();
				 * g2d.setColor(Color.BLACK); nextIsSize = false; } else
				 * if(getPress() == 2){ Canvas.setSize(362, 362); image = new
				 * BufferedImage(362, 362, BufferedImage.TYPE_INT_ARGB);
				 * this.repaint(); this.revalidate(); g2d = (Graphics2D)
				 * image.getGraphics(); g2d.setColor(Color.BLACK); nextIsSize =
				 * false; } }
				 */
				else if (nextIsColor == true) {
					if (colorCount == 0) {
						tempRed = tempRed + inputType;
						colorCount++;
					} else if (colorCount == 1) {
						tempRed = tempRed + inputType;
						colorCount++;
					} else if (colorCount == 2) {
						tempGreen = tempGreen + inputType;
						colorCount++;
					} else if (colorCount == 3) {
						tempGreen = tempGreen + inputType;
						colorCount++;
					} else if (colorCount == 4) {
						tempBlue = tempBlue + inputType;
						colorCount++;
					} else if (colorCount == 5) {
						tempBlue = tempBlue + inputType;
						colorCount++;
					}
					System.out.println("Count is " + colorCount);
					System.out.println("TempRed is " + tempRed
							+ "TempGreen is " + tempGreen + "TempBlue is "
							+ tempBlue);
					if (colorCount == 6) {
						System.out.println("Color Changing...");
						try {
							g2d.setColor(new Color(Integer
									.parseInt(tempRed, 16), Integer.parseInt(
									tempGreen, 16), Integer.parseInt(tempBlue,
									16)));
							currentColor.setText("Color: " + tempRed
									+ tempGreen + tempBlue);
							colors.setBackground(new Color(Integer.parseInt(
									tempRed, 16), Integer.parseInt(tempGreen,
									16), Integer.parseInt(tempBlue, 16)));
							currentColor.setText("Color: " + tempRed
									+ tempGreen + tempBlue);
							System.out.println("Color Changed");
						} catch (Exception E) {
							status.setText("Color Change Failed");
						}
						nextIsColor = false;
						colorCount = 0;
						tempRed = "";
						tempGreen = "";
						tempBlue = "";
						keyInput.setText("Input: ");
					}
				}
			} else {
				if (inputType == 'X') {
					nextIsX = true;
				} else if (inputType == 'Y') {
					nextIsY = true;
				} else if (inputType == 'C') {
					nextIsColor = true;
					System.out.println("C Pressed");
				} else if (inputType == 'N') {
					Integer x = 0;
					Integer y = 0;
					Integer width = 362;
					Integer height = 362;
					g2d.setColor(Color.WHITE);
					g2d.fillRect(x, y, width, height);
					g2d.setColor(new Color(255, 0, 255));
					repaint();
					System.out.println("N Pressed");
				} else if (inputType == 'S') {
					nextIsSize = true;
					System.out.println("S Pressed");
				} else if (inputType == 'P') {
					try {
						File outputfile = new File("SavedImage.png");
						ImageIO.write(image, "png", outputfile);
						System.out.println("Image Saved");
					} catch (IOException e1) {
						System.out.println("failed to save");
					}
				}
			}
			Integer x = currentx;
			Integer y = currenty;
			Integer width = 1;
			Integer height = 1;
			if (x != previousX || y != previousY) {
				g2d.drawRect(x, y, width, height);
				previousX = x;
				previousY = y;
				repaint();
				System.out.println("pixel drawn");
			}
			count = 0;
			// wait = true;
		} catch (Exception E) {
			status.setText("waiting for input");
		}
	}
};