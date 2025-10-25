# Negative Space Software - Glassmorphism Design System

## Overview
This comprehensive style guide documents the glassmorphism design system used across all Negative Space Software products and interfaces. Use this guide to maintain consistency when implementing glassmorphic interfaces in our applications, or when prompting AI agents to create glass-effect UIs that align with our brand identity.

## Core Design Principles

### 1. **Transparency & Blur**
The foundation of glassmorphism is the combination of semi-transparent backgrounds with backdrop blur effects.

```css
/* Standard glass effect */
background: rgba(255,255,255,0.1);
backdrop-filter: blur(10px);
-webkit-backdrop-filter: blur(10px);
```

### 2. **Layered Depth**
Create visual hierarchy through multiple layers of transparency and blur:
- Background layer: Solid black (#000000)
- Decorative orbs: Radial gradients for ambient lighting
- Glass containers: Semi-transparent with backdrop blur
- Nested elements: Additional transparency layers

### 3. **Subtle Borders**
All glass elements should have delicate borders for definition:
```css
border: 1px solid rgba(255,255,255,0.2);
box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1), 
            inset 0 0 0 1px rgba(255,255,255,0.2);
```

## Design Tokens

### Colors
```css
/* Background Colors */
--background-primary: #000000;       /* Solid black background */

/* Glass Backgrounds */
--glass-light: rgba(255,255,255,0.1);
--glass-medium: rgba(255,255,255,0.2);
--glass-heavy: rgba(255,255,255,0.3);
--glass-dark: rgba(0,0,0,0.2);
--glass-darker: rgba(0,0,0,0.3);

/* Semantic Colors */
--color-success: rgba(40,167,69,0.3);
--color-danger: rgba(220,53,69,0.3);
--color-warning: #ffc107;

/* Text Colors */
--text-primary: white;
--text-secondary: rgba(255,255,255,0.9);
--text-muted: rgba(255,255,255,0.7);
```

### Spacing
```css
--spacing-xs: 4px;
--spacing-s: 8px;
--spacing-ms: 12px;
--spacing-m: 16px;
--spacing-l: 24px;
--spacing-xl: 32px;
--spacing-xxl: 40px;
```

### Border Radius
- Large containers: `20px`
- Medium elements: `12px-16px`
- Small elements: `8px`
- Circular elements: `50%`

### Typography
- Font Family: Inter, Monospaced Variant 
- Base Size: `1rem`
- Weights: 400 (normal), 500 (medium), 600 (semi-bold), 700 (bold)

## Icons

### Lucide Icon System
Negative Space Software uses [Lucide](https://lucide.dev) as the official icon library. Lucide provides clean, consistent, and minimalist SVG icons that perfectly complement our glassmorphic design aesthetic.

#### Icon Implementation
All icons should be implemented as inline SVG elements with consistent styling:

```html
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <!-- Icon paths here -->
</svg>
```

#### Standard Icon Sizes
- **Small icons**: 16px (navigation, inline elements)
- **Medium icons**: 24px (buttons, form elements, principle icons)
- **Large icons**: 32px (product cards, featured elements)
- **Extra large icons**: 48px (contact icons, hero elements)

#### Icon Styling Guidelines
```css
/* Standard icon styling */
.icon {
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
  fill: none;
}

/* Icon containers */
.icon-container {
  display: flex;
  align-items: center;
  justify-content: center;
}
```

#### Primary Icons Used
Based on our current implementation, these are the primary Lucide icons:

**Navigation & UI:**
- `chevron-down` - Dropdown arrows, expandable sections
- `menu` - Hamburger menu (when needed)

**Content & Actions:**
- `file-text` - Documents, notes, Notecognito product
- `layers` - Text processing, Detextify product
- `target` - Focus, precision, archery metaphor
- `palette` - Design, customization, creativity
- `key` - Security, access, licensing

**Contact & Communication:**
- `user` - Person, profile, name
- `mail` - Email communication
- `phone` - Phone contact

#### Icon Color Guidelines
Icons should always use `currentColor` to inherit text color:
- On glass backgrounds: White (`#ffffff`)
- On hover states: Maintain current color
- For semantic states: Use appropriate semantic colors

#### Icon Accessibility
- Always include descriptive `aria-label` attributes
- Use `role="img"` for decorative icons
- Ensure sufficient contrast (4.5:1 minimum)
- Provide text alternatives when necessary

#### Implementation Examples

**Product Icon (Large)**
```html
<div class="product-icon" role="img" aria-label="Notecognito icon - Note-taking app">
  <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/>
    <polyline points="14,2 14,8 20,8"/>
    <line x1="16" x2="8" y1="13" y2="13"/>
    <line x1="16" x2="8" y1="17" y2="17"/>
    <polyline points="10,9 9,9 8,9"/>
  </svg>
</div>
```

**Principle Icon (Medium)**
```html
<div class="principle-icon">
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="12" cy="12" r="10"/>
    <circle cx="12" cy="12" r="6"/>
    <circle cx="12" cy="12" r="2"/>
  </svg>
</div>
```

**Contact Icon (Medium)**
```html
<div class="contact-icon">
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/>
    <circle cx="12" cy="7" r="4"/>
  </svg>
</div>
```

#### Adding New Icons
When adding new Lucide icons:

1. **Find the icon** at [lucide.dev](https://lucide.dev)
2. **Copy the SVG** content (paths and shapes)
3. **Apply standard attributes**:
   ```html
   width="24" height="24" viewBox="0 0 24 24" fill="none" 
   stroke="currentColor" stroke-width="2" stroke-linecap="round" 
   stroke-linejoin="round"
   ```
4. **Test** the icon at different sizes
5. **Ensure accessibility** with proper labels

#### Migration from Other Icon Libraries
When migrating from other icon libraries (like Iconoir):
- Maintain semantic meaning (archery → target)
- Keep consistent sizing within containers
- Preserve accessibility attributes
- Test visual hierarchy and contrast

## Component Patterns

### 1. **Glass Container**
```css
.glass-container {
  background: rgba(255,255,255,0.1);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border-radius: 20px;
  padding: 32px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1), 
              inset 0 0 0 1px rgba(255,255,255,0.2);
  border: 1px solid rgba(255,255,255,0.2);
}
```

### 2. **Glass Button**
```css
.glass-button {
  padding: 8px 16px;
  background: rgba(255,255,255,0.2);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  color: white;
  border: 1px solid rgba(255,255,255,0.3);
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.glass-button:hover {
  background: rgba(255,255,255,0.3);
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0,0,0,0.2);
}
```

### 3. **Glass Input**
```css
.glass-input {
  background: rgba(255,255,255,0.1);
  border: 1px solid rgba(255,255,255,0.3);
  border-radius: 8px;
  padding: 8px 12px;
  color: white;
  transition: all 0.3s ease;
}

.glass-input:focus {
  background: rgba(255,255,255,0.15);
  border-color: rgba(255,255,255,0.5);
  outline: none;
}
```

### 4. **Glass Toggle**
```css
.glass-toggle {
  background: rgba(255,255,255,0.2);
  border: 1px solid rgba(255,255,255,0.3);
  border-radius: 14px;
  /* Toggle thumb */
  .thumb {
    background: white;
    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
  }
}
```

## Animation Patterns

### 1. **Hover Transitions**
All interactive elements should have smooth transitions:
```css
transition: all 0.3s ease;
```

### 2. **Hover Transforms**
- Buttons: `translateY(-2px)`
- Navigation items: `translateX(4px)`
- Cards: Scale or slight rotation

### 3. **Loading States**
```css
@keyframes pulse {
  0% { opacity: 1; }
  50% { opacity: 0.5; }
  100% { opacity: 1; }
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
```

### 4. **Entry Animations**
```css
@keyframes slideIn {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}
```

## Background Design

### 1. **Solid Black Background**
```css
background: var(--background-primary);
/* or directly: */
background: #000000;
```

### 2. **Decorative Orbs**
Position ambient light orbs using pseudo-elements to add visual interest on the black background:
```css
/* Top-right orb */
position: absolute;
width: 400px;
height: 400px;
background: radial-gradient(circle, 
  rgba(255,255,255,0.1) 0%, 
  transparent 70%);
top: -200px;
right: -200px;
border-radius: 50%;

/* Bottom-left orb for balance */
position: absolute;
width: 300px;
height: 300px;
background: radial-gradient(circle, 
  rgba(255,255,255,0.05) 0%, 
  transparent 60%);
bottom: -150px;
left: -150px;
border-radius: 50%;
```

## Best Practices

### 1. **Performance**
- Use `will-change` sparingly for animated elements
- Combine multiple box-shadows instead of multiple elements
- Limit blur radius to maintain performance

### 2. **Accessibility**
- Maintain sufficient contrast ratios
- Use `.visually-hidden` class for screen reader content
- Ensure all interactive elements have focus states

### 3. **Consistency**
- Always use the defined spacing variables
- Maintain consistent blur values (10px standard)
- Use the same transition duration (0.3s)

### 4. **Hierarchy**
- Background: Lowest opacity (0.05-0.1)
- Containers: Medium opacity (0.1-0.2)
- Interactive elements: Higher opacity (0.2-0.3)
- Active states: Highest opacity (0.3-0.4)

## Implementation Checklist

When implementing glassmorphic UI:

- [ ] Apply backdrop-filter with -webkit prefix
- [ ] Add semi-transparent background
- [ ] Include subtle border (rgba white 0.2)
- [ ] Add box-shadow for depth
- [ ] Implement hover states with transform
- [ ] Ensure smooth transitions (0.3s ease)
- [ ] Test on different backgrounds
- [ ] Verify text readability
- [ ] Check performance with multiple elements
- [ ] Validate accessibility contrast

## Example Prompt for AI Agents

When requesting glassmorphic UI from AI agents, use this template:

```
Create a [component type] with glassmorphism styling:
- Semi-transparent background (rgba(255,255,255,0.1))
- Backdrop blur filter (10px)
- Subtle border (1px solid rgba(255,255,255,0.2))
- Box shadow for depth
- Smooth hover transitions (0.3s ease)
- Transform on hover (translateY or translateX)
- Border radius (20px for containers, 8px for small elements)
- White text on glass backgrounds
- Clean, modern typography
```

## Platform Considerations

### macOS
- Add 28px top padding for titlebar
- Use `-webkit-app-region: drag` for window dragging
- Apply `-webkit-app-region: no-drag` to interactive areas

### Cross-Platform
- Always include -webkit prefixes for backdrop-filter
- Test blur effects on different GPUs
- Provide fallbacks for non-supporting browsers

This style guide ensures consistent implementation of the Negative Space Software glassmorphism design system across all our products and client interfaces.